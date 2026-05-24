#!/usr/bin/env bash
# analyze-trivy.sh — trivy report를 kiro-cli로 분석하여 .trivy-dismissed.json 갱신
# Usage: bash analyze-trivy.sh [trivy-report.json]
set -euo pipefail

REPORT="${1:-/root/trivy-report.json}"
DISMISSED="${DISMISSED_FILE:-/root/.trivy-dismissed.json}"
TODAY=$(date +%Y-%m-%d)
REVIEW_AFTER=$(date -d "+6 months" +%Y-%m-%d 2>/dev/null || date -v+6m +%Y-%m-%d)

if [ ! -f "$REPORT" ]; then
  cat >&2 << 'GUIDE'
ERROR: trivy report not found.

To set up trivy scanning:
  1. Install trivy:
     curl -sfL https://raw.githubusercontent.com/aquasecurity/trivy/main/contrib/install.sh | sudo sh -s -- -b /usr/local/bin

  2. Add to root crontab (sudo crontab -e):
     0 20 * * * /usr/local/bin/trivy rootfs / --pkg-types os --scanners vuln --format json --output /root/trivy-report.json > /root/trivy-report.log 2>&1

  3. Run manually to generate first report:
     sudo trivy rootfs / --pkg-types os --scanners vuln --format json --output /root/trivy-report.json
GUIDE
  exit 1
fi

if ! command -v kiro &>/dev/null; then
  cat >&2 << 'GUIDE'
ERROR: kiro-cli not found.

To install kiro-cli:
  https://kiro.dev/docs/getting-started/

Then run this script again to analyze trivy results.
GUIDE
  exit 1
fi

# 현재 dismissed 파일 로드
if [ -f "$DISMISSED" ]; then
  dismissed_cves=$(python3 -c "import json; d=json.load(open('$DISMISSED')); print(' '.join(d.keys()))")
else
  dismissed_cves=""
  echo '{}' > "$DISMISSED"
fi

# CRITICAL+HIGH CVE 목록 추출 (미dismissed 항목만)
cve_list=$(python3 - << 'PYEOF'
import json, sys, os

report = json.load(open(os.environ.get('REPORT', '/root/trivy-report.json')))
dismissed_file = os.environ.get('DISMISSED', '/root/.trivy-dismissed.json')
dismissed = json.load(open(dismissed_file)) if os.path.exists(dismissed_file) else {}

# review_after 지난 항목은 dismissed에서 제외
today = os.environ.get('TODAY', '')
active_dismissed = {}
for cve, info in dismissed.items():
    if info.get('review_after', '9999') > today:
        active_dismissed[cve] = info

vulns = {}
for result in report.get('Results', []):
    for v in (result.get('Vulnerabilities') or []):
        cve = v.get('VulnerabilityID', '')
        sev = v.get('Severity', '')
        if sev in ('CRITICAL', 'HIGH') and cve not in active_dismissed:
            if cve not in vulns:
                vulns[cve] = {
                    'severity': sev,
                    'packages': [],
                    'title': (v.get('Title') or '')[:120],
                    'description': (v.get('Description') or '')[:300],
                }
            vulns[cve]['packages'].append(v.get('PkgName', ''))

for cve, info in sorted(vulns.items(), key=lambda x: x[1]['severity']):
    pkgs = ', '.join(sorted(set(info['packages'])))
    print(f"{cve}\t{info['severity']}\t{pkgs}\t{info['title']}")
PYEOF
)

if [ -z "$cve_list" ]; then
  echo "No new CRITICAL/HIGH CVEs to analyze."
  exit 0
fi

echo "=== CVEs to analyze ===" >&2
echo "$cve_list" | head -20 >&2
echo "" >&2

# kiro-cli에 분석 요청
HOSTNAME=$(hostname)
PROMPT=$(cat << PROMPT_EOF
You are analyzing trivy security scan results for server: $HOSTNAME

For each CVE below, determine if it should be dismissed (not actively exploitable on this system).
Consider: Is the vulnerable software actually running? Is it just installed as a dependency?
Is the specific vulnerable functionality used? Is there a compensating control?

Format your response as JSON only, no other text:
{
  "CVE-XXXX-YYYY": {
    "dismiss": true/false,
    "reason": "brief explanation"
  }
}

CVEs to analyze (format: CVE\tSeverity\tPackages\tTitle):
$cve_list

System context:
- Hostname: $HOSTNAME
- Running processes: $(ps aux --no-headers | awk '{print $11}' | sort -u | grep -v '^\[' | head -30 | tr '\n' ', ')
- Listening ports: $(ss -tlnp 2>/dev/null | awk 'NR>1{print $4}' | tr '\n' ', ')
PROMPT_EOF
)

echo "Sending to kiro-cli for analysis..." >&2
RESPONSE=$(echo "$PROMPT" | kiro chat --no-stream 2>/dev/null || echo "{}")

# JSON 추출 및 dismissed 파일 업데이트
python3 - << PYEOF
import json, re, os, sys

response = """$RESPONSE"""
dismissed_file = os.environ.get('DISMISSED', '/root/.trivy-dismissed.json')
today = os.environ.get('TODAY', '')
review_after = os.environ.get('REVIEW_AFTER', '')

# JSON 블록 추출
m = re.search(r'\{[\s\S]*\}', response)
if not m:
    print("Could not parse kiro response as JSON", file=sys.stderr)
    sys.exit(1)

analysis = json.loads(m.group(0))
dismissed = json.load(open(dismissed_file)) if os.path.exists(dismissed_file) else {}

added = []
for cve, info in analysis.items():
    if info.get('dismiss'):
        dismissed[cve] = {
            'reason': info.get('reason', ''),
            'dismissed_at': today,
            'dismissed_by': 'kiro',
            'review_after': review_after,
        }
        added.append(cve)

with open(dismissed_file, 'w') as f:
    json.dump(dismissed, f, indent=2)

print(f"Added {len(added)} dismissed CVEs: {', '.join(added)}")
print(f"Total dismissed: {len(dismissed)}")
print(f"Saved to {dismissed_file}")
PYEOF
