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

DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

role=${1:base}

if [ "$role" != "base" ]; then
  echo "============================
Role: $role
============================="
  if [ "$role" = "linuxdev" ]; then
    echo "Will also install...
  - terraform
  - docker
  - microk8s
"
  fi
fi

ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
distro_name=$(grep '^ID=' /etc/os-release | cut -d '=' -f2)

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

# Install software-properties-common if available
if apt-cache show software-properties-common >/dev/null 2>&1; then
  sudo apt install -y software-properties-common
fi

if [ "$role" = "linuxdev" ]; then
  $DIR/install_microk8s.sh
  $DIR/install_docker.sh
fi

# homebrew
if [ -z "$(which brew || echo '')" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi
# kubectl
if [ -z "$(kubectl version --client)" ]; then
  brew install kubectl
  # echo Installing kubectl
  # curl -LO "https://dl.k8s.io/release/$(curl -L -s https://dl.k8s.io/release/stable.txt)/bin/linux/amd64/kubectl"
  # sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
fi

if [ "$skip_devtools" ]; then exit 0; fi

# Install dev tools

pip3 install --user pynvim

# homebrew
if [ -z "$(which brew || echo '')" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
  eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
fi
brew update
brew install vim neovim graphviz httpie opentofu

if ([[ -n "$DISPLAY" ]] && xset q >/dev/null 2>&1) || [[ -n "$WAYLAND_DISPLAY" ]]; then
  # install GUI apps
  brew install alacritty
fi

