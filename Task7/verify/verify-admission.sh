#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "$0")/.." && pwd)"
fail=0

echo "audit-zone labels: $(kubectl get ns audit-zone -o jsonpath='{.metadata.labels}')"

check_denied() {
  local file="$1"
  local out code
  set +e
  out="$(sed -E 's/^(  name: ).*/\1check-denied/' "$file" | kubectl apply --dry-run=server -f - 2>&1)"
  code=$?
  set -e
  if [[ $code -ne 0 && "$out" == *"violates PodSecurity"* ]]; then
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
  out="$(kubectl apply --dry-run=server -f "$file" 2>&1)"
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

check_denied "$dir/insecure-manifests/01-privileged-pod.yaml"
check_denied "$dir/insecure-manifests/02-hostpath-pod.yaml"
check_denied "$dir/insecure-manifests/03-root-user-pod.yaml"
check_allowed "$dir/secure-manifests/01-secure.yaml"
check_allowed "$dir/secure-manifests/02-secure.yaml"
check_allowed "$dir/secure-manifests/03-secure.yaml"

exit "$fail"
