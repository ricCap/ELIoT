#!/bin/bash

set pipefail -euo

# clean up previous configurations
echo y | sudo kubeadm reset
sudo rm -rf /etc/cni/net.d
sudo rm -f $HOME/.kube/config

sudo kubeadm init

mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config

kubectl apply -f https://docs.projectcalico.org/v3.14/manifests/calico.yaml
