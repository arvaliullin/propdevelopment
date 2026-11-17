task5_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: task5-controller
task5-controller:
	kubectl apply -f https://raw.githubusercontent.com/kubernetes-sigs/kube-network-policies/main/install.yaml
	kubectl rollout status daemonset/kube-network-policies -n kube-system --timeout=180s

.PHONY: task5-apps
task5-apps:
	kubectl run front-end-app --image=nginx --labels role=front-end --expose --port 80
	kubectl run back-end-api-app --image=nginx --labels role=back-end-api --expose --port 80
	kubectl run admin-front-end-app --image=nginx --labels role=admin-front-end --expose --port 80
	kubectl run admin-back-end-api-app --image=nginx --labels role=admin-back-end-api --expose --port 80

.PHONY: task5-apply
task5-apply:
	kubectl apply -f $(task5_dir)/non-admin-api-allow.yaml
	kubectl apply -f $(task5_dir)/admin-api-allow.yaml

.PHONY: task5-all
task5-all: task5-controller task5-apps task5-apply

.PHONY: task5-check-front
task5-check-front:
	bash $(task5_dir)/check.sh http://back-end-api-app role=front-end
	bash $(task5_dir)/check.sh http://admin-back-end-api-app role=front-end

.PHONY: task5-check-admin
task5-check-admin:
	bash $(task5_dir)/check.sh http://admin-back-end-api-app role=admin-front-end
	bash $(task5_dir)/check.sh http://back-end-api-app role=admin-front-end

.PHONY: task5-check-other
task5-check-other:
	bash $(task5_dir)/check.sh http://front-end-app
	bash $(task5_dir)/check.sh http://back-end-api-app
	bash $(task5_dir)/check.sh http://admin-front-end-app
	bash $(task5_dir)/check.sh http://admin-back-end-api-app

.PHONY: task5-check
task5-check: task5-check-front task5-check-admin task5-check-other
