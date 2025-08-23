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

#!/bin/bash
if [ "$PRODUCTION" ]; then
  skip_devtools=1
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
  git \
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
  net-tools

if [ "$skip_devtools" ]; then exit 0; fi

# Install dev tools

sudo apt install -y \
  vim-gtk3 `# with python-vim` \
  graphviz \
  python3-pynvim `# vim plugin` \

# delta for gitdiff
if [ -z "$(delta --version)" ]; then
  deltaUrl=$(wget -O- -q https://github.com/dandavison/delta/releases | sed -ne "s/^.*\"\([^\"]*delta_[^\"]*_$ARCH\.deb\)\".*/\1/p")
  echo delta url: $deltaUrl
  if [ -n "$deltaUrl" ]; then
    mkdir -p tmp
    wget https://github.com/$deltaUrl -P tmp/
    sudo dpkg -i `ls tmp/*.deb` && rm tmp -rf
  fi
fi

# pip
pipx install httpie

