#!/bin/sh

# macos.sh
#
# system utils for MacOS
#
# sudo required
#
# x64, arm64

if [ "$PRODUCTION" ]; then
  skip_devtools=1
fi

# homebrew
if [ -z "$(which brew || echo '')" ]; then
  /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
fi

brew update
brew install htop \
  pipx \
  jq \
  java \
  tmux \
  the_silver_searcher \
  wget

if [ "$skip_devtools" ]; then exit 0; fi

# Install dev tools

pipx install pynvim

brew install git-lfs \
  neovim \
  httpie \
  graphviz

# install GUI apps
brew install alacritty