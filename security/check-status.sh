#!/usr/bin/env bash
# 보안 서비스 상태 빠른 확인

echo "=== 서비스 상태 ==="
for svc in suricata vnstat fail2ban; do
    status=$(systemctl is-active "$svc" 2>/dev/null)
    printf "  %-12s %s\n" "$svc" "$status"
done

echo ""
echo "=== CopyFail 완화 상태 ==="
if grep -q "algif_aead" /etc/modprobe.d/disable-algif.conf 2>/dev/null; then
    echo "  algif_aead 비활성화 설정: ✓ 적용됨"
else
    echo "  algif_aead 비활성화 설정: ✗ 미적용 (setup.sh 재실행 필요)"
fi
lsmod | grep -q algif_aead && echo "  algif_aead 모듈: ✗ 로드됨 (위험)" || echo "  algif_aead 모듈: ✓ 미로드"

echo ""
echo "=== 커널 버전 ==="
uname -r

echo ""
echo "=== VPN 피어 수 ==="
docker exec wg-easy wg show all 2>/dev/null | grep -c "^peer:" || echo "  wg-easy 미실행"
