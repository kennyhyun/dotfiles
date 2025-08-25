#!/bin/sh

# install mictok8s
# ubuntu/debian
# x64/arm64

if [ -z "$(snap microk8s --version)" ]; then
  sudo apt install -y snapd
  sudo snap install snapd
  sudo snap install microk8s --classic
fi

