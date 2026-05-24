#!/usr/bin/env bash
# 공통 보안 설정 (모든 Linux 환경)
# - CopyFail 완화, fail2ban, vnstat
set -e

# ── 1. 패키지 설치 ──────────────────────────────────────────
echo "[1] 공통 보안 패키지 설치..."
sudo apt-get install -y vnstat fail2ban

# ── 2. CopyFail (CVE-2026-31431) 완화 ───────────────────────
echo "[2] CopyFail 완화 적용 (algif_aead 비활성화)..."
echo "install algif_aead /bin/false" | sudo tee /etc/modprobe.d/disable-algif.conf > /dev/null
sudo rmmod algif_aead 2>/dev/null && echo "  algif_aead 언로드 완료" || echo "  algif_aead 이미 미로드 상태"

# ── 3. vnstat 트래픽 통계 ───────────────────────────────────
echo "[3] vnstat 설정..."
IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
sudo vnstat -i "$IFACE" --add 2>/dev/null || true
sudo systemctl enable --now vnstat
echo "  vnstat 실행 중"

# ── 4. fail2ban SSH 보호 ────────────────────────────────────
echo "[4] fail2ban 설정..."
sudo tee /etc/fail2ban/jail.d/sshd-local.conf > /dev/null << 'EOF'
[sshd]
enabled  = true
maxretry = 5
bantime  = 1h
findtime = 10m
EOF
sudo systemctl enable --now fail2ban
echo "  fail2ban 실행 중 (SSH 보호 활성)"
