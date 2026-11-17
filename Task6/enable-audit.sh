#!/usr/bin/env bash
set -euo pipefail

node="${AUDIT_NODE:-desktop-control-plane}"
policy="$(mktemp)"
manifest="$(mktemp)"
trap 'rm -f "$policy" "$manifest"' EXIT

cat > "$policy" <<'EOF'
apiVersion: audit.k8s.io/v1
kind: Policy
rules:
  - level: RequestResponse
    verbs: ["create", "delete", "update", "patch", "get", "list"]
    resources:
      - group: ""
        resources: ["pods", "secrets", "configmaps", "serviceaccounts", "roles", "rolebindings"]
  - level: Metadata
    resources:
      - group: "*"
        resources: ["*"]
EOF

docker cp "$policy" "$node:/etc/kubernetes/audit-policy.yaml"
docker exec "$node" touch /var/log/audit.log
docker cp "$node:/etc/kubernetes/manifests/kube-apiserver.yaml" "$manifest"
root="$(cd "$(dirname "$0")/.." && pwd)"
uv run --project "$root" python "$root/Task6/patch_apiserver.py" "$manifest"
docker cp "$manifest" "$node:/etc/kubernetes/manifests/kube-apiserver.yaml"

for _ in $(seq 1 40); do
  if kubectl get --raw=/readyz >/dev/null 2>&1; then
    cid="$(docker exec "$node" crictl ps -q --name kube-apiserver | head -1)"
    if docker exec "$node" crictl inspect "$cid" | grep -q audit-policy-file; then
      exit 0
    fi
  fi
  sleep 3
done

echo "audited apiserver did not become ready" >&2
exit 1
