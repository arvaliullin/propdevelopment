"""Отбирает подозрительные события из audit.log."""

import argparse
import json
import sys
from pathlib import Path


def main() -> None:
    args = parse_args()
    events = [event for event in read_events(args.log) if suspicious(event)]
    args.out.write_text(json.dumps(events, ensure_ascii=False, indent=2) + "\n")


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Отфильтровать подозрительные события audit.log")
    parser.add_argument("log", type=Path)
    parser.add_argument("out", type=Path)
    return parser.parse_args()


def read_events(path: Path) -> list[dict]:
    if not path.is_file():
        sys.exit(f"missing {path}")
    events = []
    for line in path.read_text().splitlines():
        if line.strip():
            events.append(json.loads(line))
    return events


def suspicious(event: dict) -> bool:
    ref = event.get("objectRef") or {}
    user = event.get("user") or {}
    impersonated = (event.get("impersonatedUser") or {}).get("username") or ""
    stage = event.get("stage")
    verb = event.get("verb")
    resource = ref.get("resource")
    if (
        resource == "secrets"
        and verb in {"get", "list"}
        and stage == "ResponseComplete"
        and (
            "monitoring" in impersonated
            or (user.get("username") == "kubernetes-admin" and ref.get("namespace") == "kube-system")
        )
    ):
        return True
    if ref.get("subresource") == "exec" and stage == "ResponseComplete":
        return True
    if resource == "pods" and verb == "create" and stage == "ResponseComplete" and privileged(event):
        return True
    if (
        resource == "rolebindings"
        and ref.get("name") == "escalate-binding"
        and verb == "create"
        and stage == "ResponseComplete"
    ):
        return True
    uri = event.get("requestURI") or ""
    name = ref.get("name") or ""
    return "audit-policy" in uri.lower() or "audit-policy" in name.lower()


def privileged(event: dict) -> bool:
    containers = ((event.get("requestObject") or {}).get("spec") or {}).get("containers") or []
    return any((container.get("securityContext") or {}).get("privileged") is True for container in containers)


if __name__ == "__main__":
    main()
