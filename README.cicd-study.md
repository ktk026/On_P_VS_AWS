# GitHub Actions / GHCR 공부 정리

이 문서는 Shoply 프로젝트에서 사용한 GitHub Actions, GHCR, Docker 이미지 전달 방식을 공부용으로 정리한 문서다.

## 전체 목적

CI/CD 작업의 핵심 목적은 Shoply 서비스를 Docker 이미지로 만들고, GitHub Container Registry(GHCR)에 올린 뒤, 온프레미스 Kubernetes와 AWS EKS가 동일한 이미지를 가져가서 실행할 수 있게 만드는 것이다.

전체 흐름:

```text
코드 변경
-> GitHub Actions 실행
-> 서비스별 Docker 이미지 빌드
-> GHCR Push
-> Kubernetes / Argo CD에서 동일 이미지 Pull
```

이렇게 하면 온프레미스와 AWS EKS가 서로 다른 인프라를 쓰더라도 같은 애플리케이션 버전으로 테스트할 수 있다.

## GitHub Actions Workflow

현재 GitHub Actions 파일:

```text
.github/workflows/docker-build-test.yml
```

이 workflow는 Docker 이미지를 빌드하고, push 이벤트일 때 GHCR에 이미지를 올린다.

실행 조건:

```yaml
push:
  branches:
    - dev
    - cicd

pull_request:
  branches:
    - dev
```

의미:

- `dev` 브랜치에 push하면 실행된다.
- `cicd` 브랜치에 push하면 실행된다.
- `dev` 브랜치로 Pull Request를 만들면 실행된다.

## Workflow가 하는 일

현재 workflow의 흐름은 아래와 같다.

```text
1. 소스 코드 checkout
2. Docker 버전 확인
3. 서비스별 Docker 이미지 build
4. gateway 서비스 health check
5. push 이벤트일 때 GHCR 로그인
6. GHCR에 이미지 tag / push
```

## 빌드 대상 서비스

현재 GitHub Actions matrix에 들어가 있는 서비스:

| 서비스 | 이미지 이름 | 빌드 경로 |
|---|---|---|
| frontend | `shoply-frontend` | `./app/shoply` |
| gateway | `shoply-gateway` | `./app/shoply/gateway` |
| user | `shoply-user` | `./app/shoply/services/user` |
| product | `shoply-product` | `./app/shoply/services/product` |
| inventory | `shoply-inventory` | `./app/shoply/services/inventory` |

현재 workflow에는 `order`, `payment`가 아직 포함되어 있지 않다.
수동 push 스크립트에는 `order`, `payment`가 포함되어 있으므로, 나중에 GitHub Actions에도 추가하는 것이 좋다.

## Gateway Health Check

workflow에서는 `gateway` 서비스만 별도로 컨테이너 실행 후 health check를 한다.

동작:

```text
gateway 이미지 build
-> docker run으로 gateway 컨테이너 실행
-> http://localhost:4000/health 요청
-> 응답이 성공하면 gateway 기본 실행 확인
```

관련 명령:

```bash
docker run -d --name gateway-test -p 4000:4000 shoply-gateway:test
sleep 5
curl -f http://localhost:4000/health
```

이 단계는 단순히 이미지가 빌드되는지만 보는 것이 아니라, gateway가 컨테이너로 실제 실행 가능한지도 확인하기 위한 검증이다.

## GHCR Push

GHCR은 GitHub Container Registry의 줄임말이다.

이 프로젝트에서는 서비스별 Docker 이미지를 GHCR에 저장한다.

예시:

```text
ghcr.io/ktk026/shoply-frontend:dev
ghcr.io/ktk026/shoply-gateway:dev
ghcr.io/ktk026/shoply-user:dev
ghcr.io/ktk026/shoply-product:dev
ghcr.io/ktk026/shoply-inventory:dev
```

workflow에서는 push 이벤트일 때만 GHCR에 로그인하고 이미지를 push한다.

```yaml
if: github.event_name == 'push'
```

Pull Request에서는 이미지 build와 테스트만 하고, GHCR push는 하지 않는다.

## GHCR_TOKEN

현재 workflow는 GHCR 로그인에 GitHub Secret을 사용한다.

필요한 Secret:

```text
GHCR_TOKEN
```

토큰 권한:

```text
read:packages
write:packages
```

주의:

- 토큰은 절대 Git에 올리면 안 된다.
- 토큰이 노출되면 즉시 폐기하고 새로 발급해야 한다.
- 이미지 pull만 하는 서버라면 `read:packages` 권한만 있어도 된다.

## 수동 GHCR Push 스크립트

GitHub Actions가 아니라 로컬에서 직접 이미지를 빌드하고 GHCR에 올릴 때 사용하는 스크립트도 있다.

파일:

```text
msa_shoply/scripts/push-ghcr.sh
```

역할:

```text
docker compose build
-> 로컬 이미지 생성
-> ghcr.io/<OWNER>/shoply-<service>:<TAG>로 tag
-> docker push
```

대상 서비스:

```text
user
gateway
frontend
product
inventory
order
payment
```

실행 예시:

```bash
cd msa_shoply
GHCR_OWNER=ktk026 IMAGE_TAG=dev ./scripts/push-ghcr.sh
```

수동 push는 GitHub Actions를 거치지 않고 직접 이미지를 올려야 할 때 사용한다.

## 이미지 파일로 전달하는 방식

GHCR을 사용하지 않고 Docker 이미지를 파일로 묶어서 서버로 전달하는 방식도 준비되어 있다.

관련 파일:

```text
msa_shoply/scripts/export-images.sh
msa_shoply/scripts/import-and-run.sh
```

`export-images.sh` 역할:

```text
Shoply 이미지 build
-> docker save로 shoply-images.tar 생성
-> docker-compose.release.yml, .env.example, DB seed 파일 복사
-> msa_shoply_release.tar.gz 생성
```

`import-and-run.sh` 역할:

```text
shoply-images.tar docker load
-> .env 없으면 .env.example 복사
-> docker compose up -d
```

이 방식은 레지스트리 접근이 어렵거나, 이미지 파일을 직접 전달해야 하는 상황에서 사용할 수 있다.
현재 최종 방향은 GHCR Pull 방식이지만, 파일 전달 방식은 백업 배포 방식으로 의미가 있다.

## CI/CD 문서

관련 문서:

```text
cicd/README.md
```

이 문서에는 아래 내용이 정리되어 있다.

- GitHub Actions 기반 CI/CD
- GHCR 이미지 규칙
- 브랜치 기준
- GHCR 로그인 방법
- 수동 이미지 push 방법
- 앞으로 해야 할 작업

브랜치 역할:

| 브랜치 | 용도 |
|---|---|
| `main` | 최종 안정 버전 |
| `dev` | 통합 테스트 |
| `cicd` | CI/CD, GHCR, 배포 자동화 작업 |

## 현재까지 한 작업의 의미

지금까지 한 CI/CD 작업의 의미는 아래와 같다.

```text
Shoply 서비스를 Docker 이미지로 빌드할 수 있게 했다.
GitHub Actions에서 서비스별 이미지 빌드를 자동화했다.
gateway 서비스는 컨테이너 실행과 health check까지 검증했다.
GHCR에 이미지를 push할 수 있는 구조를 만들었다.
온프레미스와 AWS EKS가 같은 이미지를 사용할 수 있는 기반을 만들었다.
```

발표에서는 이렇게 설명할 수 있다.

```text
CI/CD는 GitHub Actions와 GHCR을 기반으로 구성했습니다.
서비스별 Docker 이미지를 자동으로 빌드하고 GHCR에 push하여,
온프레미스 Kubernetes와 AWS EKS가 동일한 이미지 태그를 사용하도록 설계했습니다.
이를 통해 두 환경의 성능 비교에서 애플리케이션 버전 차이를 줄이고 공정한 실험 조건을 만들었습니다.
```

## 앞으로 개선할 부분

### 1. order / payment 서비스 workflow 추가

현재 GitHub Actions matrix에는 아래 서비스가 포함되어 있다.

```text
frontend
gateway
user
product
inventory
```

하지만 Shoply 전체 서비스에는 `order`, `payment`도 있다.
수동 push 스크립트에는 이미 포함되어 있으므로, GitHub Actions에도 추가하는 것이 좋다.

### 2. 이미지 태그 전략 개선

현재 workflow는 `dev` 태그로 push한다.

```text
ghcr.io/ktk026/shoply-gateway:dev
```

실험과 배포 재현성을 높이려면 commit SHA 태그도 같이 push하는 것이 좋다.

예시:

```text
ghcr.io/ktk026/shoply-gateway:dev
ghcr.io/ktk026/shoply-gateway:<commit-sha>
```

### 3. Argo CD 이미지 업데이트 방식 결정

GHCR에 이미지를 올린 뒤 Kubernetes가 어떤 태그를 사용할지 결정해야 한다.

가능한 방식:

| 방식 | 설명 |
|---|---|
| manifest tag 직접 수정 | K8s YAML의 image tag를 직접 변경 |
| Argo CD Image Updater | GHCR의 새 태그를 감지해 자동 반영 |
| 실험용 고정 태그 사용 | 실험마다 명시적 태그를 수동 지정 |

팀 프로젝트에서는 우선 실험용 고정 태그를 쓰는 방식이 가장 단순하다.

### 4. 이미지 보안 스캔 추가

추후에는 Trivy 같은 도구로 Docker 이미지 취약점 스캔을 추가할 수 있다.

예시 흐름:

```text
Docker build
-> Trivy scan
-> 문제가 없으면 GHCR push
```

### 5. 배포 실패 시 rollback 기준 정리

CI/CD는 이미지를 만드는 것에서 끝나지 않고, 배포 실패 시 어떻게 되돌릴지도 정해야 한다.

정리해야 할 내용:

- 이전 이미지 태그로 되돌리는 방법
- Argo CD sync 실패 시 대응
- 배포 후 health check 실패 시 rollback 기준

## 관련 파일 요약

| 파일 | 역할 |
|---|---|
| `.github/workflows/docker-build-test.yml` | GitHub Actions Docker build / GHCR push workflow |
| `cicd/README.md` | CI/CD와 GHCR 운영 기준 문서 |
| `msa_shoply/scripts/push-ghcr.sh` | 로컬에서 GHCR로 수동 push |
| `msa_shoply/scripts/export-images.sh` | Docker 이미지를 tar 파일로 묶는 release package 생성 |
| `msa_shoply/scripts/import-and-run.sh` | tar로 전달받은 이미지를 서버에서 load 후 실행 |
