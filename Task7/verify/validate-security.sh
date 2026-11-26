#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

kubectl rollout status deployment/gatekeeper-controller-manager -n gatekeeper-system --timeout=30s
kubectl rollout status deployment/gatekeeper-audit -n gatekeeper-system --timeout=30s
kubectl get k8sdenyprivileged.constraints.gatekeeper.sh deny-privileged
kubectl get k8sdenyhostpath.constraints.gatekeeper.sh deny-hostpath
kubectl get k8srequirenonroot.constraints.gatekeeper.sh require-nonroot

check_denied() {
  local file="$1"
  local name="$2"
  local out code
  set +e
  out="$(sed 's/namespace: audit-zone/namespace: gatekeeper-check/' "$file" | kubectl apply --dry-run=server -f - 2>&1)"
  code=$?
  set -e
  if [[ $code -ne 0 && "$out" == *"validation.gatekeeper.sh"* && "$out" == *"$name"* ]]; then
    echo "denied  $file"
  else
    echo "FAIL    $file"
    echo "$out"
    fail=1
  fi
}

check_allowed() {
  local file="$1"
  local out code
  set +e
  out="$(sed 's/namespace: audit-zone/namespace: gatekeeper-check/' "$file" | kubectl apply --dry-run=server -f - 2>&1)"
  code=$?
  set -e
  if [[ $code -eq 0 ]]; then
    echo "allowed $file"
  else
    echo "FAIL    $file"
    echo "$out"
    fail=1
  fi
}

check_denied "$dir/insecure-manifests/01-privileged-pod.yaml" deny-privileged
check_denied "$dir/insecure-manifests/02-hostpath-pod.yaml" deny-hostpath
check_denied "$dir/insecure-manifests/03-root-user-pod.yaml" require-nonroot
check_allowed "$dir/secure-manifests/01-secure.yaml"
check_allowed "$dir/secure-manifests/02-secure.yaml"
check_allowed "$dir/secure-manifests/03-secure.yaml"

echo "violations deny-privileged $(kubectl get k8sdenyprivileged.constraints.gatekeeper.sh deny-privileged -o jsonpath='{.status.totalViolations}')"
echo "violations deny-hostpath $(kubectl get k8sdenyhostpath.constraints.gatekeeper.sh deny-hostpath -o jsonpath='{.status.totalViolations}')"
echo "violations require-nonroot $(kubectl get k8srequirenonroot.constraints.gatekeeper.sh require-nonroot -o jsonpath='{.status.totalViolations}')"

exit "$fail"
