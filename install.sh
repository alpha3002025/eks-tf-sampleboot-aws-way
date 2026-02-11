#!/bin/bash
set -e

# Parse arguments
for arg in "$@"; do
  case $arg in
    --cluster-name=*)
      cluster_name="${arg#*=}"
      shift
      ;;
    *)
      # Unknown option
      ;;
  esac
done

if [ -z "$cluster_name" ]; then
  echo "Error: Cluster name is required."
  echo "Usage: $0 --cluster-name=<cluster_name>"
  exit 1
fi

echo "Installing resources for cluster: $cluster_name"

cd ecr/overtake-springbootsample
terraform init
terraform plan --parallelism 3
terraform apply -auto-approve

cd ../../external/github
terraform init
terraform plan --parallelism 3
terraform apply -auto-approve

cd ../../isra_alb/eksd_apnortheast2
terraform init
terraform plan --parallelism 3 -var="cluster_name=$cluster_name"
terraform apply -var="cluster_name=$cluster_name" -auto-approve

echo "Installing AWS Load Balancer Controller via Helm..."
# ALB Controller와 ExternalDNS 설치 시, ServiceAccount가 이미 Terraform으로 생성되어 있으므로 (create=false),
# ServiceAccount의 Annotation(eks.amazonaws.com/role-arn)이 이미 잘 설정되어 있는지 확인해야 합니다.
helm repo add eks https://aws.github.io/eks-charts
helm repo update
helm upgrade --install aws-load-balancer-controller eks/aws-load-balancer-controller \
  -n kube-system \
  --set clusterName=$cluster_name \
  --set serviceAccount.create=false \
  --set serviceAccount.name=aws-load-balancer-controller

cd ../../isra_externaldns/eksd_apnortheast2
terraform init
terraform plan --parallelism 3 -var="cluster_name=$cluster_name"
terraform apply -var="cluster_name=$cluster_name" -auto-approve

echo "Installing ExternalDNS via Helm..."
# ALB Controller와 ExternalDNS 설치 시, ServiceAccount가 이미 Terraform으로 생성되어 있으므로 (create=false),
# ServiceAccount의 Annotation(eks.amazonaws.com/role-arn)이 이미 잘 설정되어 있는지 확인해야 합니다.
helm repo add bitnami https://charts.bitnami.com/bitnami
helm repo update
helm upgrade --install external-dns bitnami/external-dns \
  -n kube-system \
  --set provider=aws \
  --set aws.zoneType=public \
  --set txtOwnerId=$cluster_name \
  --set policy=sync \
  --set serviceAccount.create=false \
  --set serviceAccount.name=external-dns

cd ../../kms/eksd_apnortheast2
terraform init
terraform plan --parallelism 3 -var="cluster_name=$cluster_name"
terraform apply -var="cluster_name=$cluster_name" -auto-approve

cd ../../secretsmanager/eksd_apnortheast2
terraform init
terraform plan --parallelism 3 -var="cluster_name=$cluster_name"
terraform apply -var="cluster_name=$cluster_name" -auto-approve

cd ../../podidentity/eksd_apnortheast2
terraform init
terraform plan --parallelism 3 -var="cluster_name=$cluster_name"
terraform apply -var="cluster_name=$cluster_name" -auto-approve
cd ../..
