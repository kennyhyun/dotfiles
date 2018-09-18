# Dotfiles

My personal dotfiles.

## Zsh

consider using zsh and [oh-my-zsh](https://github.com/robbyrussell/oh-my-zsh)

first install zsh (like `sudo apt install zsh`) and

```
sh -c "$(wget https://raw.githubusercontent.com/robbyrussell/oh-my-zsh/master/tools/install.sh -O -)"
```

## Installation

Clone this repository to your home directory and run the init script.

```shell
cd ~
git clone git@github.com:kennyhyun/dotfiles.git

./dotfiles/init.sh
```

## iTerm 2

Use iTerm 2 on Mac and set `Preferences > Profiles > Terminal > Terminal Emulation > Report Terminal Type` to `xterm-256color`.

'Pastel (Dark Background)' preset is my favorite.

## Zsh

At the bottom of `~/.zshrc`:

```shell
source ~/dotfiles/.zshrc
```

## Git

At the top of `~/.gitconfig`:

```
[include]
  path = ~/dotfiles/.gitconfig
```

