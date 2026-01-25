# dotfiles

This repo is supposed to cloned to a user's home directory

Installs and configure tools for Linux servers and macOS

## What's included

- **Package Management**: Homebrew for both Linux and macOS
- **Development Tools**: awscli, deno, Node.js (via nvm), vim, neovim
- **Shell**: zsh with oh-my-zsh, tmux
- **Terminal**: Alacritty with custom configuration
- **Utilities**: git, jq, httpie, fzf, and more


## preparation

### terminal emulator

If you are using Windows, you will need Windows Terminal or [kitty](http://www.9bis.net/kitty/#!index.md) or [putty](https://www.chiark.greenend.org.uk/~sgtatham/putty/) to connect to the VM

Or [Windows Terminal](https://docs.microsoft.com/en-us/windows/terminal/install) or [Alacritty](https://github.com/alacritty/alacritty/releases)

### create a user

Replace `username` to yours.
Run following commands one by one.

```bash
sudo useradd -s /bin/bash -m username
sudo usermod -aG sudo username
sudo passwd username
```

### use sudo without password

Additionally, for `sudo` without password,

```
sudo visudo
```

Add `username ALL=(ALL) NOPASSWD:ALL` to the last line

## install

For both Linux and macOS:

```bash
git clone https://github.com/kennyhyun/server-dotfiles.git dotfiles
dotfiles/init.sh
```

Log off and on again to use the env.

