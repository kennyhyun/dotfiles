#!/usr/bin/env bash
# WireGuard VPN + 보안 현황 통합 모니터링
# 사용: sudo vpn-monitor.sh

CACHE_FILE="/tmp/geoip-cache.txt"

# IP → "도시, 국가 (ISP)" 조회 (캐시 활용)
geoip() {
    local ip="$1"
    # 사설 IP는 조회 안 함
    if [[ "$ip" =~ ^(10\.|192\.168\.|172\.(1[6-9]|2[0-9]|3[01])\.|127\.) ]]; then
        echo "내부망"
        return
    fi
    # 캐시 확인
    local cached
    cached=$(grep "^$ip " "$CACHE_FILE" 2>/dev/null | cut -d' ' -f2-)
    if [ -n "$cached" ]; then
        echo "$cached"
        return
    fi
    # 신규 조회
    local result
    result=$(curl -sf --max-time 3 "https://ipinfo.io/$ip/json" \
        | python3 -c "
import sys, json
d = json.load(sys.stdin)
city    = d.get('city', '')
country = d.get('country', '')
org     = d.get('org', '')
# org에서 AS번호 제거: 'AS16509 Amazon' → 'Amazon'
org = ' '.join(org.split()[1:]) if org else ''
print(f'{city}, {country}  ({org})')
" 2>/dev/null)
    if [ -n "$result" ]; then
        echo "$ip $result" >> "$CACHE_FILE"
        echo "$result"
    else
        echo "조회 실패"
    fi
}

echo "════════════════════════════════════════════════════════"
echo " 보안 현황 모니터링  $(date '+%Y-%m-%d %H:%M:%S')"
echo "════════════════════════════════════════════════════════"

# ── WireGuard VPN 피어 현황 ──────────────────────────────────
echo ""
echo "▶ WireGuard VPN 피어 현황"
echo "──────────────────────────"
wg_output=$(docker exec wg-easy wg show all 2>/dev/null)
if [ -z "$wg_output" ]; then
    echo "  wg-easy 컨테이너 미실행"
else
    # endpoint IP만 추출해서 geolocation 추가
    echo "$wg_output" | while IFS= read -r line; do
        if [[ "$line" =~ ^[[:space:]]*endpoint:[[:space:]]*(.*):([0-9]+)$ ]]; then
            peer_ip="${BASH_REMATCH[1]}"
            peer_port="${BASH_REMATCH[2]}"
            geo=$(geoip "$peer_ip")
            echo "$line  →  $geo"
        else
            echo "$line"
        fi
    done
fi

# ── 현재 외부 연결 ───────────────────────────────────────────
echo ""
echo "▶ 현재 외부 연결 (established)"
echo "──────────────────────────"
printf "%-22s %-22s %-6s %s\n" "로컬" "원격" "프로세스" "위치"
echo "──────────────────────────────────────────────────────────"
ss -tnp state established 2>/dev/null \
    | grep -v "^Recv\|127.0.0.1\|::1\|10.152\|10.1.98" \
    | while read -r _ _ local remote proc _rest; do
        remote_ip="${remote%:*}"
        remote_ip="${remote_ip//\[/}"
        remote_ip="${remote_ip//\]/}"
        proc_name=$(echo "$proc" | grep -oP '"\K[^"]+' | head -1)
        geo=$(geoip "$remote_ip")
        printf "%-22s %-22s %-10s %s\n" "$local" "$remote" "${proc_name:-?}" "$geo"
    done

# ── Suricata 경고 ────────────────────────────────────────────
echo ""
echo "▶ Suricata 침입탐지 경고 (최근 20건)"
echo "──────────────────────────"
if [ -s /var/log/suricata/fast.log ]; then
    tail -20 /var/log/suricata/fast.log
else
    echo "  경고 없음"
fi

# ── fail2ban 차단 현황 ───────────────────────────────────────
echo ""
echo "▶ fail2ban 차단 현황"
echo "──────────────────────────"
sudo fail2ban-client status sshd 2>/dev/null || echo "  fail2ban 미실행"

# ── 트래픽 통계 ──────────────────────────────────────────────
echo ""
echo "▶ 트래픽 통계 (최근 3시간)"
echo "──────────────────────────"
IFACE=$(ip route get 8.8.8.8 2>/dev/null | awk '{print $5; exit}')
vnstat -i "$IFACE" -h 3 2>/dev/null || echo "  vnstat 데이터 수집 중..."
