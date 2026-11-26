#!/usr/bin/env bash
set -euo pipefail

url="${1:?url required}"
label="${2:-}"
name="check-$$-$RANDOM"

if [ -n "$label" ]; then
  out="$(kubectl run "$name" --rm -i --restart=Never --image=alpine --labels "$label" --command -- wget -qO- --timeout=2 "$url" 2>&1 || true)"
  who="$label"
else
  out="$(kubectl run "$name" --rm -i --restart=Never --image=alpine --command -- wget -qO- --timeout=2 "$url" 2>&1 || true)"
  who="no-label"
fi

if printf '%s' "$out" | grep -q 'Welcome to nginx'; then
  echo "open    ${who} -> ${url}"
else
  echo "closed  ${who} -> ${url}"
fi
