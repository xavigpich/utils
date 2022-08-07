#!/bin/sh

# Install snapd
sudo apt update
sudo apt install snapd

# Install microk8s
sudo snap install microk8s --classic
microk8s status --wait-ready

# Enable services/plugins
microk8s enable dns registry istio
