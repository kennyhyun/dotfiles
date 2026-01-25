# Immich

Self-hosted photo and video management solution.

## 사용법

```bash
cd ~/dotfiles/services/immich
./start.sh
```

접속: http://localhost:2283

## 명령어

- 시작: `./start.sh` 또는 `docker compose up -d`
- 중지: `docker compose down`
- 로그 확인: `docker compose logs -f`
- 재시작: `docker compose restart`

## 설정

`.env` 파일에서 데이터베이스 비밀번호 및 업로드 위치를 변경할 수 있습니다.
