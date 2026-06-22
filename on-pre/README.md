# On-Premise Environment

이 디렉토리는 온프레미스 Kubernetes 환경 구성과 운영 문서를 관리한다.

## 목표

- kubeadm 기반 Kubernetes 클러스터 구성
- 고정된 워커 노드 환경에서 Shoply 실행
- HPA가 Pod를 늘리려 할 때 노드 자원 한계로 Pending이 발생하는 구간 관찰
- 동일 부하 조건에서 AWS EKS 자동 확장 환경과 비교

## 주요 구성

| 영역 | 내용 |
|---|---|
| Kubernetes | kubeadm 기반 클러스터 |
| CNI | Flannel |
| Ingress | Nginx Ingress, NodePort 30080 |
| 이미지 레지스트리 | GHCR |
| Monitoring | Prometheus/Grafana 연동 |

## 실험 관점

온프레미스 환경은 EKS처럼 노드를 자동으로 추가하지 않는다. 이 차이가 실험의 핵심 변수다.

따라서 Pending Pod, Error Rate, P95 latency가 증가하는 지점은 실패가 아니라 측정해야 할 운영 한계점이다.

## 관련 문서

- [../msa_shoply/k8s/README.md](../msa_shoply/k8s/README.md)
- [../docs/experiment-plan.md](../docs/experiment-plan.md)
- [../load-test/k6/README.md](../load-test/k6/README.md)
