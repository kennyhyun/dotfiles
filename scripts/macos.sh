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
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

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

brew install git-lfs \
  neovim \
  pynvim \
  httpie \
  graphviz
