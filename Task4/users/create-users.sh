#!/usr/bin/env bash
set -euo pipefail

out_dir="$(cd "$(dirname "$0")" && pwd)/certs"
mkdir -p "$out_dir"

create_user() {
  local name="$1"
  local group="$2"
  local key="${out_dir}/${name}.key"
  local csr="${out_dir}/${name}.csr"
  local crt="${out_dir}/${name}.crt"
  local request

  openssl genrsa -out "$key" 2048
  openssl req -new -key "$key" -out "$csr" -subj "/CN=${name}/O=${group}"
  request="$(base64 -w0 "$csr")"

  kubectl delete csr "$name" --ignore-not-found
  kubectl apply -f - <<EOF
apiVersion: certificates.k8s.io/v1
kind: CertificateSigningRequest
metadata:
  name: ${name}
spec:
  request: ${request}
  signerName: kubernetes.io/kube-apiserver-client
  usages:
    - client auth
EOF
  kubectl certificate approve "$name"
  local cert=""
  local attempt
  for attempt in $(seq 1 20); do
    cert="$(kubectl get csr "$name" -o jsonpath='{.status.certificate}')"
    if [ -n "$cert" ]; then
      printf '%s' "$cert" | base64 -d > "$crt"
      break
    fi
    sleep 1
  done
  if [ ! -s "$crt" ]; then
    echo "certificate for ${name} was not issued" >&2
    exit 1
  fi
  kubectl config set-credentials "$name" \
    --client-certificate="$crt" \
    --client-key="$key" \
    --embed-certs=true
}

create_user devops-user devops
create_user infosec-user infosec
create_user viewer-user viewers
create_user sales-dev sales-developers
create_user housing-dev housing-developers
create_user finance-dev finance-developers
create_user data-dev data-developers
