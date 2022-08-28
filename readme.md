# dotfiles

This repo is supposed to cloned to a user's home directory

Installs and configure tools for Linux servers


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

```bash
git clone https://github.com/kennyhyun/server-dotfiles.git dotfiles
dotfiles/init.sh
```

Log off and on again to use the env.

