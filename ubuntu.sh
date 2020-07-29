sudo apt update
sudo apt install -y git tmux net-tools htop vim silversearcher-ag \
python3-pip \
linux-tools-common \
apt-transport-https ca-certificates software-properties-common \
curl zsh # zsh

# vim plugins
sudo pip3 install pynvim

## Build git diff-highlight
#pushd /usr/share/doc/git/contrib/diff-highlight
#sudo make
#popd
