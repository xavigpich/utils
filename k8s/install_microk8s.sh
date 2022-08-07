#!/bin/sh

if [[ "$OSTYPE" == "linux-gnu"* ]]; then
	sudo apt update
	sudo apt install snapd
	sudo snap install microk8s --classic

elif [[ "$OSTYPE" == "darwin"* ]]; then
	brew install ubuntu/microk8s/microk8s
	microk8s install
fi

microk8s status --wait-ready
microk8s enable dns registry istio
