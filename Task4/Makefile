task4_dir := $(patsubst %/,%,$(dir $(lastword $(MAKEFILE_LIST))))

.PHONY: task4-users
task4-users:
	bash $(task4_dir)/users/create-users.sh

.PHONY: task4-roles
task4-roles:
	bash $(task4_dir)/roles/create-roles.sh

.PHONY: task4-bind
task4-bind:
	bash $(task4_dir)/bindings/bind-roles.sh

.PHONY: task4-all
task4-all: task4-users task4-roles task4-bind
