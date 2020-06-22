#!/usr/bin/env bash

pushd ~

# -- NeoVim
mkdir -p ~/.config
pushd ~/.config
ln -s ~/dotfiles/.vim nvim
popd
# For python3 support. Otherwise you'll get:
# [deoplete] deoplete.nvim does not work with this version.
# [deoplete] It requires Neovim with Python3 support("+python3").
pip3 install --upgrade pip
pip3 install neovim

popd
