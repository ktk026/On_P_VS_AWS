# 협업 규칙

## 브랜치 전략

```text
main     → 최종 안정 버전
develop  → 통합 테스트 브랜치

aws      → AWS 환경 작업
on-pre   → 온프레미스 환경 작업
cicd     → CI/CD 작업
```

---

## 작업 흐름

### 1. 작업 전 최신 상태 가져오기

```bash
git checkout 본인브랜치
git pull origin develop
```

---

### 2. 작업 후 Commit & Push

```bash
git add .
git commit -m "작업 내용 요약"
git push origin 본인브랜치
```

---

### 3. Pull Request 생성

```text
본인 브랜치 → develop
```

통합 테스트 후:

```text
develop → main
```

---

## 폴더 작업 규칙

### AWS 팀
- `aws/` 폴더 중심 작업

### On-Pre 팀
- `on-pre/` 폴더 중심 작업

### CI/CD 팀
- `cicd/` 폴더 중심 작업

### 공통
- `app/` : 공통 애플리케이션 코드
- `database/` : DB 관련 파일
- `load-test/` : 부하 테스트 관련 파일
- `docs/` : 프로젝트 문서

---

## 커밋 메시지 예시

```bash
git commit -m "AWS EKS 구조 추가"
git commit -m "on-pre monitoring 설정 추가"
git commit -m "CI/CD 초기 구조 작성"
git commit -m "README 수정"
```

---

## 주의사항

- main 브랜치에 직접 push 금지
- 작업 전 develop 최신화 필수
- 다른 팀 담당 폴더 임의 수정 금지
- 민감 정보(.env, key 등) 업로드 금지