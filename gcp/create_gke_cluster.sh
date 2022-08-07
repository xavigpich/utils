#!/bin/sh

# Set Project
gcloud projects list
gcloud config set project <project_id>
myRegion="us-central1-a"
gcloud config set compute/zone $myRegion

# Enable GKE API
gcloud enable services container.googleapis.com

# Create GKE Cluster
cluster_name="gke-cluster-1"
cluster_nodes=4
gcloud container clusters create $cluster_name $cluster_nodes 

# Verify
kubeclt get nodes