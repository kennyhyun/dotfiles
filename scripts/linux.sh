#!/bin/bash
if [ "$PRODUCTION" ]; then
  skip_devtools=1
fi

distro_name=$(lsb_release -i|cut -f2)
if [ "$distro_name" = "Ubuntu" ]; then
  perf_package=linux-tools-common
else
  perf_package=linux-perf
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


# pip
pipx install \
  httpie

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

