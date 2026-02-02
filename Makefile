.PHONY: init plan apply destroy clean fmt validate

init:
	terraform init

plan:
	terraform plan

apply:
	terraform apply

destroy:
	terraform destroy

clean:
	rm -rf .terraform .terraform.lock.hcl

fmt:
	terraform fmt -recursive

validate:
	terraform validate
