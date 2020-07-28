sudo apt update
sudo apt install git tmux net-tools htop vim silversearcher-ag\

# neovim needs both of python2 and python3.
# How can I make it work on both? Maybe install directory?
#sudo apt install
python3-pip\

# perf command
#sudo apt install
linux-tools-common\

# docker
apt-transport-https ca-certificates software-properties-common\

# zsh
curl zsh

# vim plugins
sudo pip3 install pynvim

## Build git diff-highlight
#pushd /usr/share/doc/git/contrib/diff-highlight
#sudo make
#popd

# Node.js
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | zsh
