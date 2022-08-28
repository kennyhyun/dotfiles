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
  vim-gtk `# with python-vim` \
  silversearcher-ag \
  zsh \
  graphviz

# pip
sudo pip3 install \
  pynvim `# vim plugin` \
  httpie

# docker-compose
if [ -f "/usr/local/bin/docker-compose" ]; then
  echo "-----\ndocker-compose aleady exists"
  docker-compose --version
else
  echo "-----\nInstalling docker-compose...."
  sudo pip3 install requests --upgrade
  dc_version=${COMPOSE_VERSION:-1.29.2}
  dc_version_url=/docker/compose/releases/download/${dc_version}/docker-compose-$(uname -s)-$(uname -m)
  if [ -z "$dc_version_url" ];then
    echo "Could not find the docker-compose url, please install manually from $github_compose_release_url"
  else
    docker_compose_url=https://github.com${dc_version_url}
    echo Downloading: $docker_compose_url
    sudo wget $docker_compose_url -O /usr/local/bin/docker-compose -q --show-progress --progress=bar:force
    sudo chmod +x /usr/local/bin/docker-compose
    docker-compose --version
  fi
fi

## wordtsar
mkdir -p ~/.appImages
wordtsar_bin_url=`http https://sourceforge.net/projects/wordtsar/best_release.json |jq -r '.platform_releases.linux.url'`
wordtsar_bin_path=$HOME/.appImages/`echo $wordtsar_bin_url | grep -o '\/Releases\/\(.*\)\/WordTsar[^?]\+' | cut -d'/' -f3`.AppImage
if [ -f "$wordtsar_bin_path" ]; then
  echo "$wordtsar_bin_path found"
else
  wget $wordtsar_bin_url -O $wordtsar_bin_path -q --show-progress --progress=bar:force
  chmod +x $wordtsar_bin_path
  sudo ln -sf $wordtsar_bin_path /usr/local/bin/wordtsar
fi
