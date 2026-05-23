# kennyx2 보안 설정

## 배경

2026년 5월 발견된 두 Linux 커널 취약점에 대응하여 구성한 보안 설정입니다.

## 대응 취약점

### CopyFail (CVE-2026-31431)
- **심각도**: CVSS 7.8 (HIGH), CISA KEV 등재
- **원리**: `authencesn` 로직 버그 → `AF_ALG` + `splice()` 체이닝 → page cache 오염 → root 획득
- **조건**: 비특권 로컬 계정만 있으면 됨, 732바이트 Python 스크립트로 수 초 내 root
- **영향**: 2017년 이후 빌드된 거의 모든 Linux 커널
- **적용 완화**: `algif_aead` 모듈 비활성화 (`/etc/modprobe.d/disable-algif.conf`)

### DirtyCred
- **원리**: UAF/Double Free 버그를 이용해 커널 힙의 credential 구조체를 교체, root 권한 획득
- **특징**: 커널 버전 무관, KASLR/SMEP/KPTI 우회, 컨테이너 탈출 가능, 탐지 매우 어려움
- **적용 완화**: 커널 업데이트, Suricata IDS, fail2ban, 컨테이너 최소 권한

## 현재 시스템 상태 (2026-05-23 기준)

| 항목 | 내용 |
|------|------|
| OS | Ubuntu 24.04 LTS |
| 커널 | 6.8.0-117-generic (재부팅 후 업그레이드 완료) |
| 실행 컨테이너 | samba, wg-easy (WireGuard VPN) |

## 설치된 보안 도구

| 도구 | 역할 |
|------|------|
| **Suricata** | 네트워크 IDS — 침입탐지, 의심 트래픽, 데이터 유출 탐지 |
| **vnstat** | 인터페이스별 트래픽 통계 누적 기록 |
| **fail2ban** | SSH 브루트포스 자동 차단 (5회 실패 시 1시간 차단) |
| **vpn-monitor.sh** | VPN 피어 현황 + 보안 경고 통합 확인 |

## 파일 구성

```
security/
├── setup.sh          # 전체 보안 설정 반복 설치 스크립트
├── vpn-monitor.sh    # 통합 모니터링 (VPN + Suricata + fail2ban + 연결 현황)
├── check-status.sh   # 서비스 상태 빠른 확인
└── README.md         # 이 문서
```

## 사용법

### 최초 설치 / 재설치

```bash
cd ~/dotfiles/security
chmod +x setup.sh vpn-monitor.sh check-status.sh
sudo ./setup.sh
```

### 일상 모니터링

```bash
# 통합 현황 확인
sudo vpn-monitor.sh

# 서비스 상태만 빠르게 확인
bash ~/dotfiles/security/check-status.sh

# Suricata 실시간 경고 감시
sudo tail -f /var/log/suricata/fast.log

# 실시간 트래픽 (연결별)
sudo iftop -i wlo1
```

### Suricata 룰 업데이트 (주기적으로 실행 권장)

```bash
sudo suricata-update
sudo systemctl restart suricata
```

## 미완료 / 추가 권장 조치

### wg-easy SYS_MODULE capability 제거 (권장)

`SYS_MODULE`은 커널 모듈 삽입 권한으로 DirtyCred 악용 가능성이 있습니다.
WireGuard 모듈이 커널에 내장된 경우 제거 가능합니다:

```bash
# 모듈 내장 여부 확인
modinfo wireguard | grep filename
# filename: (builtin) 이면 SYS_MODULE 불필요

# wg-easy docker-compose.yml에서 SYS_MODULE 제거 후 재시작
```

### seccomp 프로파일 적용 (권장)

현재 samba, wg-easy 컨테이너에 seccomp 프로파일 미적용 상태입니다:

```yaml
# docker-compose.yml
security_opt:
  - seccomp:/etc/docker/seccomp/default.json
```

### Suricata 룰 자동 업데이트 cron 설정

```bash
echo "0 3 * * 1 root suricata-update && systemctl restart suricata" \
  | sudo tee /etc/cron.d/suricata-update
```

## 네트워크 현황 (2026-05-23 기준)

| 연결 | 방향 | IP | 위치 | 용도 |
|------|------|----|------|------|
| SSH | 아웃바운드 | 43.201.0.60 | AWS 서울 | 관리 |
| SSH | 아웃바운드 | 152.67.217.118 | Oracle 춘천 | 관리 |
| SSH | 아웃바운드 | 192.9.181.175 | Oracle 시드니 | 관리 |
| SSH | 인바운드 | 103.2.171.185 | Aussie Broadband 시드니 | 본인 접속 |
| k8s API | 내부 | 10.152.183.x | MicroK8s | Kubernetes |
| VPN | 피어 | 10.8.0.2 | wg-easy | WireGuard 클라이언트 1개 등록 |
