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

echo "Uninstalling resources for cluster: $cluster_name"

cd podidentity/eksd_apnortheast2
terraform destroy -var="cluster_name=$cluster_name" -auto-approve
rm -rf .terraform*

cd ../../secretsmanager/eksd_apnortheast2
terraform destroy -var="cluster_name=$cluster_name" -auto-approve
rm -rf .terraform*

cd ../../kms/eksd_apnortheast2
terraform destroy -var="cluster_name=$cluster_name" -auto-approve
rm -rf .terraform*

# Uninstall ExternalDNS via Helm
echo "Uninstalling ExternalDNS via Helm..."
helm uninstall external-dns -n kube-system || true

cd ../../irsa_externaldns/eksd_apnortheast2
terraform destroy -var="cluster_name=$cluster_name" -auto-approve
rm -rf .terraform*

# Uninstall ALB Controller via Helm
echo "Uninstalling AWS Load Balancer Controller via Helm..."
helm uninstall aws-load-balancer-controller -n kube-system || true

cd ../../irsa_alb/eksd_apnortheast2
terraform destroy -var="cluster_name=$cluster_name" -auto-approve
rm -rf .terraform*

cd ../../external/github
terraform destroy -auto-approve
rm -rf .terraform*

cd ../../ecr/overtake-springbootsample
# ECR 삭제 전 force_delete 설정을 반영하기 위해 apply 먼저 시도 (또는 AWS CLI로 강제 삭제)
terraform apply -auto-approve
terraform destroy -auto-approve
rm -rf .terraform*
cd ../..
