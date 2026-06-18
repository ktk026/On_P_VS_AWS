# Shoply Kubernetes Manifests

이 디렉토리는 Shoply MSA를 Kubernetes에 배포하기 위한 매니페스트를 관리한다. 공통 리소스는 `common/`에 두고, 환경별 차이는 `onprem/`, `eks/`, `argocd/`에서 관리한다.

## 구조

```text
k8s/
├── common/       # Namespace, ConfigMap, Secret, Deployment, Service, HPA
├── onprem/       # 온프레미스 전용 overlay, Ingress, NodePort, MetalLB, cAdvisor
├── eks/          # EKS 전용 리소스, Karpenter 관련 설정
└── argocd/       # ArgoCD Application 매니페스트
```

현재 `common/`과 `onprem/`에는 Kustomize 진입점이 있다.

```bash
kubectl kustomize msa_shoply/k8s/common
kubectl kustomize msa_shoply/k8s/onprem
```

`eks/`는 EKS 환경 확정 후 overlay 진입점을 추가한다.

## 온프레미스 배포

온프레미스 환경은 아래 overlay를 기준으로 렌더링한다.

```bash
kubectl kustomize msa_shoply/k8s/onprem
```

직접 적용:

```bash
kubectl apply -k msa_shoply/k8s/onprem
```

ArgoCD로 배포할 경우 `argocd/shoply-onprem-app.yaml`을 사용한다.

```bash
kubectl apply -f msa_shoply/k8s/argocd/shoply-onprem-app.yaml
```

`shoply-onprem-app.yaml`의 destination은 ArgoCD에 `onprem` 클러스터가 등록되어 있다는 전제다.

```yaml
destination:
  name: onprem
  namespace: shoply
```

## GHCR 인증

GHCR 이미지가 private이면 클러스터에 image pull secret이 필요하다. GitHub PAT은 최소 `read:packages` 권한이 필요하다.

```bash
kubectl create namespace shoply --dry-run=client -o yaml | kubectl apply -f -

kubectl create secret docker-registry ghcr-secret \
  --docker-server=ghcr.io \
  --docker-username=<GITHUB_USERNAME> \
  --docker-password=<GITHUB_PAT> \
  --namespace=shoply
```

토큰은 문서, Git, 이슈, PR에 남기지 않는다.

## 배포 전 체크리스트

| 항목 | 확인 내용 |
|---|---|
| 이미지 태그 | 온프레미스와 EKS에 동일 태그 사용 |
| GHCR Secret | `shoply` namespace에 `ghcr-secret` 존재 |
| ConfigMap | DB/Redis 주소가 환경에 맞는지 확인 |
| Secret | DB 비밀번호, JWT secret 변경 |
| Ingress | 온프레미스 NodePort 또는 MetalLB 사용 방식 확인 |
| HPA | resource request/limit이 HPA 기준과 맞는지 확인 |

## 이미지 태그 원칙

실험 공정성을 위해 `latest` 대신 커밋 SHA나 명시적인 실험 태그를 사용한다.

```text
ghcr.io/ktk026/shoply-gateway:<commit-sha>
ghcr.io/ktk026/shoply-order:<commit-sha>
```

`latest`는 push 시점에 따라 실제 이미지가 달라질 수 있으므로, 온프레미스와 EKS 비교 실험에는 적합하지 않다.

## 검증 명령

```bash
kubectl get pods -n shoply -o wide
kubectl get svc -n shoply
kubectl get hpa -n shoply
kubectl get events -n shoply --sort-by=.metadata.creationTimestamp
```

렌더링 결과 확인:

```bash
kubectl kustomize msa_shoply/k8s/onprem | less
```
