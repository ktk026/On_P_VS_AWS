# Shoply Docker Image Release

이 패키지는 Shoply MSA 애플리케이션을 Docker 이미지로 전달하기 위한 실행 패키지다.

## 포함 파일

```text
msa_shoply_release/
├── docker-compose.yml
├── shoply-images.tar
├── .env.example
├── README.md
└── db/
    ├── schema.sql
    └── seed.sql
```

## 필요 조건

실행 서버에 Docker와 Docker Compose plugin이 설치되어 있어야 한다.

확인:

```bash
docker --version
docker compose version
```

## 실행 방법

압축 해제:

```bash
tar -xzf msa_shoply_release.tar.gz
cd msa_shoply_release
```

환경 파일 준비:

```bash
cp .env.example .env
```

이미지 로드:

```bash
docker load -i shoply-images.tar
```

서비스 실행:

```bash
docker compose up -d
```

## GHCR에서 이미지 Pull 방식

이미지 tar 파일을 전달하지 않고 GitHub Container Registry에서 이미지를 가져올 수도 있다.

### 이미지 Push

먼저 GitHub Personal Access Token을 준비한다.

필요 권한:

```text
write:packages
read:packages
```

GHCR 로그인:

```bash
echo "<GITHUB_TOKEN>" | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

이미지 빌드 및 push:

```bash
cd msa_shoply
GHCR_OWNER=<GITHUB_USERNAME_OR_ORG> IMAGE_TAG=latest ./scripts/push-ghcr.sh
```

예시:

```bash
GHCR_OWNER=my-github-id IMAGE_TAG=v1 ./scripts/push-ghcr.sh
```

### 팀원 서버에서 실행

팀원 서버에는 아래 파일이 필요하다.

```text
docker-compose.ghcr.yml
.env.example
db/schema.sql
db/seed.sql
```

private package라면 팀원 서버에서도 GHCR 로그인이 필요하다.

```bash
echo "<GITHUB_TOKEN>" | docker login ghcr.io -u <GITHUB_USERNAME> --password-stdin
```

실행:

```bash
cp .env.example .env
GHCR_OWNER=<GITHUB_USERNAME_OR_ORG> IMAGE_TAG=latest docker compose -f docker-compose.ghcr.yml pull
GHCR_OWNER=<GITHUB_USERNAME_OR_ORG> IMAGE_TAG=latest docker compose -f docker-compose.ghcr.yml up -d
```

public package라면 `docker login` 없이 pull할 수 있다.

상태 확인:

```bash
docker compose ps
```

## 접속 주소

```text
Frontend: http://localhost:3000
Gateway:  http://localhost:4000
```

서버에서 실행하는 경우 `localhost` 대신 서버 IP를 사용한다.

```text
Frontend: http://<SERVER_IP>:3000
Gateway:  http://<SERVER_IP>:4000
```

## 포트

| 서비스 | 포트 |
|---|---:|
| frontend | 3000 |
| gateway | 4000 |
| product | 4001 |
| inventory | 4002 |
| order | 4003 |
| payment | 4004 |
| user | 4005 |
| postgres | 5432 |
| redis | 6379 |

## 종료

```bash
docker compose down
```

DB 볼륨까지 삭제하려면:

```bash
docker compose down -v
```
