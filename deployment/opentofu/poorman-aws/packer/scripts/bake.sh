#!/usr/bin/env bash
set -euo pipefail

sudo dnf upgrade -y
sudo dnf install -y \
  awscli2 \
  docker \
  ec2-instance-connect \
  jq \
  postgresql17 \
  xfsprogs \
  zstd

sudo install -d -m 0755 /usr/local/lib/docker/cli-plugins
arch="$(uname -m)"
case "$arch" in
  x86_64) compose_arch="x86_64" ;;
  aarch64) compose_arch="aarch64" ;;
  *) echo "unsupported architecture: $arch" >&2; exit 1 ;;
esac

sudo curl -fsSL \
  "https://github.com/docker/compose/releases/download/${COMPOSE_VERSION}/docker-compose-linux-${compose_arch}" \
  -o /usr/local/lib/docker/cli-plugins/docker-compose
sudo chmod 0755 /usr/local/lib/docker/cli-plugins/docker-compose

sudo systemctl enable --now docker
sudo usermod -aG docker ec2-user

for image in $PRELOAD_IMAGES; do
  sudo docker pull "$image"
done

sudo docker version
sudo docker compose version
aws --version
psql --version

sudo dnf clean all
sudo rm -rf /var/cache/dnf /tmp/*
