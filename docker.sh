#!/usr/bin/env bash

set -e

curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -

sudo apt install software-properties-common
sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu focal stable"

sudo apt update
apt-cache policy docker-ce

sudo apt install docker-ce

sudo systemctl status docker | cat

sudo usermod -aG docker ${USER}
