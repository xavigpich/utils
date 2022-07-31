#!/bin/sh

# Get GPG key for Docker
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

# Add repository for Docker
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable"

# Add GPG key for Kubernetes
curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | sudo apt-key add -

# Add packages
cat << EOF | sudo tee /etc/apt/sources.list.d/kubernetes.list
deb https://apt.kubernetes.io/ kubernetes-xenial main
EOF

sudo apt update

# Install Docker, tools
version=1.21.0-00
sudo apt install -y docker-ce=5:19.03.10~3-0~ubuntu-focal kubelet=$version kubeadm=$version kubectl=$version
sudo apt-mark hold kubeadm kubelet kubectl

# Initialise K8s cluster
sudo kubeadm init --pod-network-cidr 192.168.0.0/16 --kubernetes-version $version

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

# Set up networking - Ex: Calico
kubectl apply -f https://docs.projectcalico.org/manifests/calico.yaml

# Generate token for worker nodes to join

