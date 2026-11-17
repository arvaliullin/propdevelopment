.PHONY: task4-users task4-roles task4-bind task4-all

task4-users:
	bash Task4/users/create-users.sh

task4-roles:
	bash Task4/roles/create-roles.sh

task4-bind:
	bash Task4/bindings/bind-roles.sh

task4-all: task4-users task4-roles task4-bind
