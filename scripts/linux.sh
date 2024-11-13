#!/bin/bash

# linux.sh
#
# system utils for Linux
#
# sudo required
#
# for ubuntu/debian
# x64, arm64
#

set -e

if [ "$PRODUCTION" ]; then
  skip_devtools=1
fi

role=${1:base}

if [ "$role" != "base" ]; then
  echo "============================
Role: $role
============================="
  if [ "$role" = "linuxdev" ]; then
    echo "Will also install...
  - terraform

"
  fi
fi

ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
distro_name=$(lsb_release -i|cut -f2)

if [ "$distro_name" = "Ubuntu" ]; then
  perf_package=linux-tools-common
else
  perf_package=linux-perf
fi

# Stop if sudo is unavailable
if [ -z "$(sudo ls)" ]; then
  echo "Please install sudo package"
  echo "eg.
su -
apt install sudo
usermod -a -G sudo USER
---
And please login again
"
  exit 2
fi

sudo apt update

# Install essential tools
sudo apt install -y \
  $perf_package \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  git git-lfs \
  htop \
  python3-pip \
  python3-venv \
  pipx \
  jq \
  curl \
  default-jre \
  tmux \
  silversearcher-ag \
  zsh \
  lshw \
  net-tools

if [ "$skip_devtools" ]; then exit 0; fi

# Install dev tools

pipx install pynvim

if [ "$role" = "linuxdev" ]; then
  # terraform
  wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg -f --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
  echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
  sudo apt update && sudo apt install terraform

  # ansible
  pipx install --include-deps ansible
fi

# homebrew
if [ -z "$(which brew || echo '')" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
brew update
brew install vim neovim graphviz httpie

if ([[ -n "$DISPLAY" ]] && xset q >/dev/null 2>&1) || [[ -n "$WAYLAND_DISPLAY" ]]; then
  # install GUI apps
  brew install alacritty
fi