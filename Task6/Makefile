task6_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: task6-audit
task6-audit:
	bash $(task6_dir)/enable-audit.sh

.PHONY: task6-simulate
task6-simulate:
	bash $(task6_dir)/simulate-incident.sh

.PHONY: task6-fetch
task6-fetch:
	docker cp desktop-control-plane:/var/log/audit.log $(task6_dir)/audit.log

.PHONY: task6-filter
task6-filter:
	uv run --project $(abspath $(task6_dir)/..) python $(task6_dir)/filter_audit.py $(task6_dir)/audit.log $(task6_dir)/audit-extract.json

.PHONY: task6-check
task6-check:
	jq 'select(.objectRef.resource=="secrets" and .verb=="get")' $(task6_dir)/audit.log
	jq 'select(.verb=="create" and .objectRef.subresource=="exec")' $(task6_dir)/audit.log
	jq 'select(.objectRef.resource=="pods" and any(.requestObject.spec.containers[]?; .securityContext.privileged==true))' $(task6_dir)/audit.log
	grep -i 'audit-policy' $(task6_dir)/audit.log || true

.PHONY: task6-all
task6-all: task6-audit task6-simulate task6-fetch task6-filter
