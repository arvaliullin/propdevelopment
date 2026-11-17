#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"

for ns in sales housing finance data; do
  kubectl create namespace "$ns" --dry-run=client -o yaml | kubectl apply -f -
done

kubectl apply -f "$dir/cluster-roles.yaml"

for ns in sales housing finance data; do
  kubectl apply -n "$ns" -f "$dir/namespace-developer.yaml"
done
