"""Добавляет флаги и тома аудита в манифест kube-apiserver."""

import argparse
import sys
from pathlib import Path

AUDIT_FLAGS = """\
    - --audit-policy-file=/etc/kubernetes/audit-policy.yaml
    - --audit-log-path=/var/log/audit.log
    - --audit-log-maxage=30
    - --audit-log-maxbackup=10
    - --audit-log-maxsize=100
"""
RUNTIME_CONFIG = "    - --runtime-config=\n"
AUDIT_MOUNTS = """\
    - mountPath: /etc/kubernetes/audit-policy.yaml
      name: audit-policy
      readOnly: true
    - mountPath: /var/log/audit.log
      name: audit-log
"""
AUDIT_VOLUMES = """\
  - hostPath:
      path: /etc/kubernetes/audit-policy.yaml
      type: File
    name: audit-policy
  - hostPath:
      path: /var/log/audit.log
      type: FileOrCreate
    name: audit-log
"""
CA_MOUNT = """\
    - mountPath: /usr/share/ca-certificates
      name: usr-share-ca-certificates
      readOnly: true
"""
CA_VOLUME = """\
      path: /usr/share/ca-certificates
      type: DirectoryOrCreate
    name: usr-share-ca-certificates
"""


def main() -> None:
    args = parse_args()
    text = args.manifest.read_text()
    args.manifest.write_text(with_audit(text))


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description="Добавить аудит в манифест kube-apiserver")
    parser.add_argument("manifest", type=Path)
    return parser.parse_args()


def with_audit(text: str) -> str:
    if "--audit-policy-file" not in text:
        if RUNTIME_CONFIG not in text:
            sys.exit("runtime-config flag not found")
        text = text.replace(RUNTIME_CONFIG, RUNTIME_CONFIG + AUDIT_FLAGS, 1)
    if "name: audit-policy" not in text:
        if CA_MOUNT not in text or CA_VOLUME not in text:
            sys.exit("apiserver volume anchors not found")
        text = text.replace(CA_MOUNT, CA_MOUNT + AUDIT_MOUNTS, 1)
        text = text.replace(CA_VOLUME, CA_VOLUME + AUDIT_VOLUMES, 1)
    return text


if __name__ == "__main__":
    main()
