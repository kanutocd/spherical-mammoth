#!/usr/bin/env bash
set -euo pipefail

sudo dnf upgrade -y
sudo dnf install -y awscli2 docker ec2-instance-connect iproute jq tar xfsprogs zstd

encoded_k3s_version="${K3S_VERSION/+/%2B}"
sudo install -d -m 0755 /opt/k3s /var/lib/rancher/k3s/agent/images
sudo curl -fsSL \
  "https://github.com/k3s-io/k3s/releases/download/${encoded_k3s_version}/k3s" \
  -o /usr/local/bin/k3s
sudo curl -fsSL \
  "https://github.com/k3s-io/k3s/releases/download/${encoded_k3s_version}/k3s-airgap-images-amd64.tar.zst" \
  -o /opt/k3s/k3s-airgap-images-amd64.tar.zst
sudo chmod 0755 /usr/local/bin/k3s

sudo systemctl enable --now docker
for image in $PRELOAD_IMAGES; do
  sudo docker pull "$image"
done
sudo docker save $PRELOAD_IMAGES | sudo zstd -T0 -10 -o /opt/k3s/spherical-mammoth-images.tar.zst
sudo systemctl disable --now docker

curl -fsSL https://get.k3s.io -o /tmp/install-k3s.sh
chmod 0755 /tmp/install-k3s.sh
sudo env \
  INSTALL_K3S_SKIP_DOWNLOAD=true \
  INSTALL_K3S_SKIP_SELINUX_RPM=true \
  INSTALL_K3S_SKIP_START=true \
  /tmp/install-k3s.sh

helm_archive="helm-${HELM_VERSION}-linux-amd64.tar.gz"
curl -fsSL "https://get.helm.sh/$helm_archive" -o "/tmp/$helm_archive"
tar -xzf "/tmp/$helm_archive" -C /tmp
sudo install -m 0755 /tmp/linux-amd64/helm /usr/local/bin/helm

sudo systemctl disable k3s.service
/usr/local/bin/k3s --version
/usr/local/bin/helm version --short
aws --version

sudo dnf clean all
sudo rm -rf /var/cache/dnf /tmp/*
