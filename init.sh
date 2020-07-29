#!/usr/bin/env bash

pushd ~

case $(uname -s) in
Darwin)
  # -- Homebrew
  ~/dotfiles/brew.sh
  # -- Karabiner
  #ln -s dotfiles/karabiner ~/.config
  # To maximize MacVim's window horizontally as well as vertically
  defaults write org.vim.MacVim MMZoomBoth 1
  ;;
Linux)
  ~/dotfiles/ubuntu.sh
  ;;
esac

#ohmyzsh
echo
echo -----------------------------
echo Installing ohmyzsh type "exit<RET>" if you see the ohmyzsh logo.
echo -----------------------------
sh -c "$(curl -fsSL https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh)"
sudo chsh -s $(which zsh) $USER

# Node.js with NVM
curl -o- https://raw.githubusercontent.com/creationix/nvm/v0.33.11/install.sh | zsh
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"
nvm install 12

# -- Vim
ln -s dotfiles/.vim .vim
ln -s dotfiles/.vimrc .vimrc
ln -s dotfiles/.gvimrc .gvimrc
ln -s dotfiles/.ideavimrc .ideavimrc

# # -- NeoVim
# mkdir -p ~/.config
# pushd ~/.config
# ln -s ~/dotfiles/.vim nvim
# popd
# # For python3 support. Otherwise you'll get:
# # [deoplete] deoplete.nvim does not work with this version.
# # [deoplete] It requires Neovim with Python3 support("+python3").
# pip3 install --upgrade pip
# pip3 install neovim

# dein.vim
pushd dotfiles
mkdir -p .vim/dein/repos
git clone https://github.com/Shougo/dein.vim .vim/dein/repos/github.com/Shougo/dein.vim
popd

# -- tmux
ln -s dotfiles/.tmux.conf .tmux.conf
mkdir -p ~/.tmux/plugins
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# fzf
git clone --depth 1 https://github.com/junegunn/fzf.git dotfiles/.fzf
ln -s dotfiles/.fzf .fzf
~/.fzf/install


# gitconfig
echo "[include]
    path = ~/dotfiles/gitconfig" >> ~/.gitconfig

popd

# add swapfile dir
mkdir -p $HOME/.vim/swapfiles
