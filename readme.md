# dotfiles

Bootstrap new systems with your familiar configuration and tools for Linux and macOS.

This repository is meant to be cloned into `~/dotfiles`. Configuration files are symlinked to your home directory for version control and easy sync across systems.

## Motivation

Managing multiple systems (personal laptops, home servers, cloud instances) with different purposes requires a flexible setup that can:
- Install common tools automatically on fresh systems
- Support different environments (development workstations, production servers, personal machines)
- Maintain consistency across Linux and macOS
- Allow customization through environment variables and options

## What's included

- **Package Management**: Homebrew for both Linux and macOS
- **Development Tools**: awscli, deno, Node.js (via nvm), vim, neovim
- **Shell**: zsh with oh-my-zsh, tmux
- **Terminal**: Alacritty with custom configuration
- **Utilities**: git, jq, httpie, fzf, and more

## Supported Platforms

- ✅ Linux (Ubuntu/Debian)
- ✅ macOS (Intel & Apple Silicon)
- 🚧 Windows (via WSL) - planned

## Usage Options

### Production Server Mode

Skip development tools and install only essential utilities:

```bash
PRODUCTION=1 dotfiles/init.sh
```

### Standard Installation

Full development environment with all tools:

```bash
dotfiles/init.sh
```


## preparation

### Setting up a Linux environment

If you need to create a Linux VM or development environment first, check out [linuxdev](https://github.com/kennyhyun/linuxdev) - it automates Linux environment setup on VMs, WSL, and cloud instances. Once your Linux environment is ready, return here to install your dotfiles.

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

## Roadmap

### Current Development
- 🔧 Homebrew-based package management (in progress)
- 🔧 macOS support enhancement
- 🔧 Alacritty terminal configuration

### Planned Features
- 📅 Windows WSL support
- 📅 Docker development environment option
- 📅 Modular installation (choose specific tool sets)
- 📅 Configuration profiles (minimal, standard, full)
- 📅 Dotfile synchronization across systems

### Future Considerations
- IDE configurations (VSCode, IntelliJ)
- Language-specific environments (Python, Go, Rust)
- Container orchestration tools (kubectl, helm)
- Cloud provider CLIs (gcloud, azure-cli)

