#!/usr/bin/env bash
# 퍼블릭 서버 보안 설정
# 적용 항목: 공통 보안 + Suricata IDS, ufw, vpn-monitor
set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
echo "[*] 메인 인터페이스: $IFACE"

# ── 공통 보안 설정 ──────────────────────────────────────────
$SCRIPT_DIR/setup-common.sh

# ── 1. 추가 패키지 설치 ─────────────────────────────────────
echo "[1] 퍼블릭 서버 패키지 설치..."
sudo apt-get install -y suricata iftop

# ── 2. Suricata IDS 설정 ────────────────────────────────────
echo "[2] Suricata 설정..."
sudo sed -i "0,/interface: /{s/interface: [a-z0-9]*/interface: $IFACE/}" /etc/suricata/suricata.yaml
sudo suricata-update 2>&1 | tail -2
sudo systemctl enable --now suricata
echo "  Suricata 실행 중 (인터페이스: $IFACE)"

# ── 3. vpn-monitor 스크립트 ─────────────────────────────────
echo "[3] vpn-monitor 스크립트 설치..."
sudo cp "$SCRIPT_DIR/vpn-monitor.sh" /usr/local/bin/vpn-monitor.sh
sudo chmod +x /usr/local/bin/vpn-monitor.sh
echo "  vpn-monitor.sh → /usr/local/bin/vpn-monitor.sh"

# ── 4. ufw 방화벽 ────────────────────────────────────────────
echo "[4] ufw 방화벽 설정..."
sudo ufw allow 22          comment "SSH"
sudo ufw allow from 192.168.9.0/24 comment "LAN"
sudo ufw allow 445         comment "samba"
sudo ufw allow 51821       comment "wg-easy webui"
sudo ufw allow 51820/udp   comment "wireguard vpn"
sudo ufw allow 9090        comment "cockpit/systemd"
sudo ufw allow 44321       comment "pmcd"
sudo ufw allow 44322       comment "pmproxy"
sudo ufw allow 44323       comment "pmproxy"
sudo ufw allow 16443       comment "microk8s api"
sudo ufw allow 10250       comment "microk8s kubelet"
sudo ufw allow 25000       comment "microk8s cluster-agent"
sudo ufw allow from 192.168.9.0/24 to any port 4330 comment "pmlogger LAN"
sudo ufw deny from 80.94.92.0/24  comment "RO brute-force"
sudo ufw deny from 92.118.39.0/24 comment "RO brute-force"
sudo ufw --force enable
echo "  ufw 활성화 완료"

echo ""
echo "[완료] 퍼블릭 서버 보안 설정이 적용되었습니다."
