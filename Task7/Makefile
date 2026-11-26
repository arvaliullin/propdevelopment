task7_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: task7-gatekeeper
task7-gatekeeper:
	kubectl apply -f https://raw.githubusercontent.com/open-policy-agent/gatekeeper/v3.23.1/deploy/gatekeeper.yaml
	kubectl rollout status deployment/gatekeeper-controller-manager -n gatekeeper-system --timeout=180s
	kubectl rollout status deployment/gatekeeper-audit -n gatekeeper-system --timeout=180s

.PHONY: task7-audit
task7-audit:
	bash $(task7_dir)/../Task6/enable-audit.sh $(task7_dir)/audit-policy.yaml

.PHONY: task7-namespace
task7-namespace:
	kubectl apply -f $(task7_dir)/01-create-namespace.yaml

.PHONY: task7-policies
task7-policies:
	kubectl apply -f $(task7_dir)/gatekeeper/constraint-templates/
	for _ in $$(seq 1 30); do \
	  kubectl get crd k8sdenyprivileged.constraints.gatekeeper.sh >/dev/null 2>&1 && \
	  kubectl get crd k8sdenyhostpath.constraints.gatekeeper.sh >/dev/null 2>&1 && \
	  kubectl get crd k8srequirenonroot.constraints.gatekeeper.sh >/dev/null 2>&1 && break; \
	  sleep 2; \
	done
	kubectl wait --for condition=established --timeout=120s \
	  crd/k8sdenyprivileged.constraints.gatekeeper.sh \
	  crd/k8sdenyhostpath.constraints.gatekeeper.sh \
	  crd/k8srequirenonroot.constraints.gatekeeper.sh
	kubectl apply -f $(task7_dir)/gatekeeper/constraints/

.PHONY: task7-secure
task7-secure:
	kubectl apply -f $(task7_dir)/secure-manifests/
	kubectl wait --for=condition=Ready pod --all -n audit-zone --timeout=180s

.PHONY: task7-verify
task7-verify:
	bash $(task7_dir)/verify/verify-admission.sh
	bash $(task7_dir)/verify/validate-security.sh

.PHONY: task7-denied
task7-denied:
	docker exec desktop-control-plane cat /var/log/audit.log | jq -c 'select(.responseStatus.code==403 and (.objectRef.namespace=="audit-zone" or .objectRef.namespace=="gatekeeper-check")) | {verb, namespace: .objectRef.namespace, name: .objectRef.name, code: .responseStatus.code, user: .user.username}'

.PHONY: task7-all
task7-all: task7-gatekeeper task7-audit task7-namespace task7-policies task7-secure task7-verify
