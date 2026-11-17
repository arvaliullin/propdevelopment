#!/usr/bin/env bash
set -euo pipefail

dir="$(cd "$(dirname "$0")" && pwd)"

kubectl apply -f "$dir/cluster-bindings.yaml"
kubectl apply -f "$dir/developer-bindings.yaml"
