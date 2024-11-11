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
sudo apt install -y \
  $perf_package \
  apt-transport-https \
  ca-certificates \
  software-properties-common \
  git \
  python3-pip \
  jq \
  curl \
  default-jre \
  tmux \
  net-tools

if [ "$skip_devtools" ]; then exit 0; fi

sudo apt install -y \
  htop \
  vim-gtk3 `# with python-vim` \
  silversearcher-ag \
  zsh \
  graphviz \
  pipx \
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

## docker-compose
#if [ -f "/usr/local/bin/docker-compose" ]; then
#  echo "-----\ndocker-compose aleady exists"
#  docker-compose --version
#else
#  echo "-----\nInstalling docker-compose...."
#  pipx install requests
#  dc_version=${COMPOSE_VERSION:-1.29.2}
#  dc_version_url=/docker/compose/releases/download/${dc_version}/docker-compose-$(uname -s)-$(uname -m)
#  if [ -z "$dc_version_url" ];then
#    echo "Could not find the docker-compose url, please install manually from $github_compose_release_url"
#  else
#    docker_compose_url=https://github.com${dc_version_url}
#    echo Downloading: $docker_compose_url
#    sudo wget $docker_compose_url -O /usr/local/bin/docker-compose -q --show-progress --progress=bar:force
#    sudo chmod +x /usr/local/bin/docker-compose
#    docker-compose --version
#  fi
#fi

