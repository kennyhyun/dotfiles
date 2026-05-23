#!/usr/bin/env bash
# kennyx2 보안 설정 반복 설치 스크립트
# 적용 항목: CopyFail 완화, Suricata IDS, vnstat, fail2ban, vpn-monitor
set -e

IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
echo "[*] 메인 인터페이스: $IFACE"

# ── 1. 패키지 설치 ──────────────────────────────────────────
echo "[1] 패키지 설치..."
sudo apt-get update -qq
sudo apt-get install -y suricata vnstat iftop fail2ban

# ── 2. CopyFail (CVE-2026-31431) 완화 ───────────────────────
echo "[2] CopyFail 완화 적용 (algif_aead 비활성화)..."
echo "install algif_aead /bin/false" | sudo tee /etc/modprobe.d/disable-algif.conf > /dev/null
sudo rmmod algif_aead 2>/dev/null && echo "  algif_aead 언로드 완료" || echo "  algif_aead 이미 미로드 상태"

# ── 3. Suricata IDS 설정 ────────────────────────────────────
echo "[3] Suricata 설정..."
sudo sed -i "s/interface: eth0/interface: $IFACE/" /etc/suricata/suricata.yaml
# 이미 변경된 경우 대비
sudo sed -i "0,/interface: /{s/interface: [a-z0-9]*/interface: $IFACE/}" /etc/suricata/suricata.yaml 2>/dev/null || true
sudo suricata-update 2>&1 | tail -2
sudo systemctl enable --now suricata
echo "  Suricata 실행 중 (인터페이스: $IFACE)"

# ── 4. vnstat 트래픽 통계 ───────────────────────────────────
echo "[4] vnstat 설정..."
sudo vnstat -i "$IFACE" --add 2>/dev/null || true
sudo systemctl enable --now vnstat
echo "  vnstat 실행 중"

# ── 5. fail2ban SSH 보호 ────────────────────────────────────
echo "[5] fail2ban 설정..."
sudo tee /etc/fail2ban/jail.d/sshd-local.conf > /dev/null << 'EOF'
[sshd]
enabled  = true
maxretry = 5
bantime  = 1h
findtime = 10m
EOF
sudo systemctl enable --now fail2ban
echo "  fail2ban 실행 중 (SSH 보호 활성)"

# ── 6. vpn-monitor 스크립트 ─────────────────────────────────
echo "[6] vpn-monitor 스크립트 설치..."
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
sudo cp "$SCRIPT_DIR/vpn-monitor.sh" /usr/local/bin/vpn-monitor.sh
sudo chmod +x /usr/local/bin/vpn-monitor.sh
echo "  vpn-monitor.sh → /usr/local/bin/vpn-monitor.sh"

echo ""
echo "[완료] 모든 보안 설정이 적용되었습니다."
echo "  확인: sudo vpn-monitor.sh"

# ── 7. ufw 방화벽 ────────────────────────────────────────────
echo "[7] ufw 방화벽 설정..."
# 기본 허용 (SSH 먼저 - 잠금 방지)
sudo ufw allow 22          comment "SSH"
sudo ufw allow from 192.168.9.0/24 comment "LAN"
# 서비스 포트
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
# 차단
sudo ufw deny from 80.94.92.0/24  comment "RO brute-force"
sudo ufw deny from 92.118.39.0/24 comment "RO brute-force"
sudo ufw --force enable
echo "  ufw 활성화 완료"
