#!/bin/sh
# Name:
#   ./kinesis-reader.sh
#
# Description:
#   Reads Kinesis stream records
#
# Mandatory Arguments: \n
#   -p --profile        AWS Profile. Cloud Account
#   -r --region         AWS Region
#   -s --stream-name    AWS Kinesis Stream Name
#   -l --limit          Limit. Amount of records
#   -o --output-file    /path/to/file
#
# Options:
#   -h --help      Show help
#
# ==============================================================================

basename="$(basename $0)"
info="
Usage: ./${basename} \n
Description: Reads Kinesis stream records \n
Mandatory Arguments: \n
  -P --profile        \t\t AWS Profile (Cloud Account) \n
  -R --region         \t\t AWS Region \n
  -S --stream-name    \t AWS Kinesis Stream Name \n
Options: \n
  -h --help           \t\t Show help \n
  -l --limit          \t\t Limit. Amount of records \n
"
info() {
	echo -e $info
}

usage="Usage: ${basename%.*} [--profile PROFILE] [--region REGION][--stream-name STREAM_NAME][-limit LIMIT]"

usage() {
	echo -e $usage
}

while test $# -gt 0; do
    case $1 in
        -P | --profile )    shift
                            if test $# -gt 0; then
                                profile="$1"
                            else
                                echo "Error: No profile specified."
                                exit 1
                            fi
 			                shift
                            ;;
        -R | --region)      shift
                            if test $# -gt 0; then
                                region="$1"
                            else
                                echo "Error: No region specified."
                                exit 1
                            fi
			                shift
                            ;;
        -S | --stream-name) shift
                            if test $# -gt 0; then
                                stream_name="$1"
                            else
                                echo "Error: No stream name specified."
                                exit 1
                            fi
			                shift
                            ;;
        -l | --limit)       shift
                            if test $# -gt 0; then
                                limit="$1"
                            fi
			                shift
                            ;;
        -h | --help )       info
                            exit 0
                            ;;
        * )                 echo "${basename}: invalid option -- '${1}'"
                            usage
                            exit 1
                            ;;
    esac
done

############################################################################ 
echo "Requirements"
echo "Checking binaries are installed ..."
if ! aws_bin="$(which aws)" 2>/dev/null; then
    echo "aws cli is missing; you can get it from https://aws.amazon.com/cli/"
    exit 1
fi
if ! jq_bin="$(which jq)" 2>/dev/null; then
    echo "jq is missing; you can get it from https://stedolan.github.io/jq/"
    exit 1
fi

echo "Checking mandatory arguments are set ..."
if [ "$profile" == "" ] || [ "$region" == "" ] || [ "$stream_name" == "" ]; then
   echo "Please ensure all mandatory fields are specified: profile, region and stream name"
   exit 1
fi
if [[ -z $limit ]]; then
    limit=1
fi

###########################################################################
echo "Connecting to Kinesis Stream"
echo "Calculating Shard ID ..."
shard_id=`aws --profile $profile --region $region kinesis describe-stream \
              --stream-name $stream_name \
              | jq -r '.StreamDescription.Shards[].ShardId'`

echo "Calculating Shard Iterator ID ..."
# TODO: Add TYPE=LATEST/AT_TIMESTAMP as argument + timestamp mins/days as optional argument
type='LATEST'
# Visit https://docs.aws.amazon.com/cli/latest/reference/kinesis/get-shard-iterator.html 
shard_iterator=`aws --profile $profile --region $region kinesis get-shard-iterator \
                    --stream-name $stream_name \
                    --shard-id $shard_id \
                    --shard-iterator-type $type \
                    --query "ShardIterator"`

echo "Waiting for new stream records ..."
records="$(aws --profile $profile --region $region kinesis get-records \
               --shard-iterator $shard_iterator \
               --limit $limit)"
check=$( jq -r '.Records' <<< "${records}" )

while [[ $check == [] ]]; do
    records="$(aws --profile $profile --region $region kinesis get-records \
               --shard-iterator $shard_iterator \
               --limit $limit)"
    check=$( jq -r '.Records' <<< "${records}" )
    sleep 1
    continue
done 

echo "Decoding records ..."
jq -r '.Records[]|.Data' <<< $records | while read data; do
    echo $data | base64 -d -
done
