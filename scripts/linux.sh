#!/usr/bin/env bash
# linux.sh — Linux 환경 설정
#
# Usage:
#   bash linux.sh [roles...] [--remove role]
#
# Roles:
#   (없음)  base only — apt 필수 패키지, zsh, tmux, git, trivy, fail2ban
#   dev     brew, vim/neovim, docker, opentofu, kubectl
#   k8s     microk8s, kubectl
#   gui     alacritty
#   server  Suricata, ufw
#   vpn     WireGuard, vpn-monitor
#
# Examples:
#   bash linux.sh                   # base only
#   bash linux.sh dev gui           # dev + GUI
#   bash linux.sh dev k8s           # dev + k8s
#   bash linux.sh server            # base + server security
#   bash linux.sh dev k8s server    # full server with dev tools
#   bash linux.sh --remove dev      # interactive removal of dev role

set -e
DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ARCH="$(uname -m | sed -e 's/x86_64/amd64/' -e 's/\(arm\)\(64\)\?.*/\1\2/' -e 's/aarch64$/arm64/')"
distro_name=$(grep '^ID=' /etc/os-release | cut -d '=' -f2 | tr -d '"')

# ── sudo 체크 ────────────────────────────────────────────────
if ! sudo -n true 2>/dev/null; then
  echo "Please configure sudo access first:
  su -
  apt install sudo
  usermod -a -G sudo $USER
  # login again"
  exit 2
fi

# ── 인수 파싱 ────────────────────────────────────────────────
REMOVE_ROLE=""
ROLES=()
while [[ $# -gt 0 ]]; do
  case "$1" in
    --remove) REMOVE_ROLE="$2"; shift 2 ;;
    base|dev|k8s|gui|server|vpn) ROLES+=("$1"); shift ;;
    *) echo "Unknown role: $1"; exit 1 ;;
  esac
done

has_role() { [[ " ${ROLES[*]} " == *" $1 "* ]]; }

# ── 제거 모드 ────────────────────────────────────────────────
if [[ -n "$REMOVE_ROLE" ]]; then
  case "$REMOVE_ROLE" in
    dev)
      echo "=== Remove: dev ==="
      PKGS="docker-ce docker-ce-cli containerd.io opentofu kubectl"
      echo "Packages to remove: $PKGS"
      read -rp "Remove these packages? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo apt-get remove -y $PKGS && sudo apt-get autoremove -y
      if command -v brew &>/dev/null; then
        BREW_PKGS="vim neovim opentofu"
        echo "Brew packages to remove: $BREW_PKGS"
        read -rp "Remove brew packages? [y/N] " ans
        [[ "$ans" =~ ^[Yy]$ ]] && brew uninstall $BREW_PKGS || true
      fi
      ;;
    k8s)
      echo "=== Remove: k8s ==="
      echo "Packages to remove: microk8s kubectl"
      read -rp "Remove microk8s? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo snap remove microk8s || true
      read -rp "Remove kubectl? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo rm -f /usr/local/bin/kubectl || true
      ;;
    gui)
      echo "=== Remove: gui ==="
      read -rp "Remove alacritty? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo snap remove alacritty 2>/dev/null || sudo apt-get remove -y alacritty || true
      ;;
    server)
      echo "=== Remove: server ==="
      echo "Packages to remove: suricata ufw"
      read -rp "Remove suricata + ufw? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo apt-get remove -y suricata ufw && sudo apt-get autoremove -y || true
      ;;
    vpn)
      echo "=== Remove: vpn ==="
      echo "Packages to remove: wireguard"
      read -rp "Remove wireguard? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo apt-get remove -y wireguard && sudo apt-get autoremove -y || true
      read -rp "Remove vpn-monitor.sh? [y/N] " ans
      [[ "$ans" =~ ^[Yy]$ ]] && sudo rm -f /usr/local/bin/vpn-monitor.sh || true
      ;;
    *) echo "Unknown role: $REMOVE_ROLE"; exit 1 ;;
  esac
  exit 0
fi

# ── 설치 모드 ────────────────────────────────────────────────
echo "============================
Roles: base${ROLES:+ ${ROLES[*]}}
============================"

# ── BASE: 항상 설치 ──────────────────────────────────────────
echo "[base] apt 업데이트..."
sudo apt update
sudo apt upgrade -y --with-new-pkgs

if [ "$distro_name" = "ubuntu" ]; then
  perf_package=linux-tools-common
else
  perf_package=linux-perf
fi

sudo apt install -y \
  $perf_package \
  apt-transport-https \
  ca-certificates \
  git git-lfs \
  htop \
  python3-pip \
  python3-venv \
  pipx \
  jq \
  curl \
  tmux \
  zsh \
  silversearcher-ag \
  net-tools \
  psmisc \
  lshw

if apt-cache show software-properties-common >/dev/null 2>&1; then
  sudo apt install -y software-properties-common
fi

echo "[base] trivy 설치..."
if ! command -v trivy &>/dev/null; then
  curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin
else
  echo "  trivy already installed ($(trivy --version 2>/dev/null | head -1))"
fi
TRIVY_CRON="0 20 * * * /usr/local/bin/trivy rootfs / --pkg-types os --scanners vuln --format json --output /root/trivy-report.json > /root/trivy-report.log 2>&1"
if ! sudo crontab -l 2>/dev/null | grep -q "trivy-report.json"; then
  (sudo crontab -l 2>/dev/null; echo "$TRIVY_CRON") | sudo crontab -
  echo "  trivy crontab registered (daily 20:00 UTC)"
fi

echo "[base] fail2ban 설치..."
sudo apt install -y fail2ban
sudo tee /etc/fail2ban/jail.d/sshd-local.conf > /dev/null << 'EOF'
[sshd]
enabled  = true
maxretry = 5
bantime  = 1h
findtime = 10m
EOF
sudo systemctl enable --now fail2ban

# ── DEV ──────────────────────────────────────────────────────
if has_role dev; then
  echo "[dev] brew, vim/neovim, docker, opentofu, kubectl..."

  if ! command -v brew &>/dev/null; then
    curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh | bash
    eval "$(/home/linuxbrew/.linuxbrew/bin/brew shellenv)"
  fi
  brew update
  brew install vim neovim opentofu

  # docker
  if ! command -v docker &>/dev/null; then
    curl -fsSL https://get.docker.com | sudo sh
    sudo usermod -aG docker "$USER"
    echo "  docker installed (re-login to use without sudo)"
  fi

  # kubectl
  if ! command -v kubectl &>/dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
  fi
fi

# ── K8S ──────────────────────────────────────────────────────
if has_role k8s; then
  echo "[k8s] microk8s, kubectl..."
  "$DIR/install_microk8s.sh"

  if ! command -v kubectl &>/dev/null; then
    curl -LO "https://dl.k8s.io/release/$(curl -Ls https://dl.k8s.io/release/stable.txt)/bin/linux/$ARCH/kubectl"
    sudo install -o root -g root -m 0755 kubectl /usr/local/bin/kubectl && rm kubectl
  fi
fi

# ── GUI ──────────────────────────────────────────────────────
if has_role gui; then
  echo "[gui] alacritty..."
  if ([[ -n "${DISPLAY:-}" ]] && xset q >/dev/null 2>&1) || [[ -n "${WAYLAND_DISPLAY:-}" ]]; then
    if command -v snap &>/dev/null; then
      sudo snap install alacritty --classic 2>/dev/null || true
    else
      echo "  snap not available, skipping alacritty"
    fi
  else
    echo "  No display detected, skipping alacritty"
  fi
fi

# ── SERVER ───────────────────────────────────────────────────
if has_role server; then
  echo "[server] Suricata, ufw..."
  IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
  sudo apt install -y suricata iftop
  sudo sed -i "0,/interface: /{s/interface: [a-z0-9]*/interface: $IFACE/}" /etc/suricata/suricata.yaml
  sudo suricata-update 2>&1 | tail -2
  sudo systemctl enable --now suricata

  sudo ufw allow 22          comment "SSH"
  sudo ufw allow from 192.168.9.0/24 comment "LAN"
  sudo ufw --force enable
  echo "  ufw enabled (SSH + LAN allowed)"
fi

# ── VPN ──────────────────────────────────────────────────────
if has_role vpn; then
  echo "[vpn] WireGuard, vpn-monitor..."
  sudo apt install -y wireguard
  sudo cp "$DIR/../security/vpn-monitor.sh" /usr/local/bin/vpn-monitor.sh
  sudo chmod +x /usr/local/bin/vpn-monitor.sh
  echo "  WireGuard installed. Configure /etc/wireguard/wg0.conf manually."
fi

echo ""
echo "Done! Roles applied: base${ROLES:+ ${ROLES[*]}}"
