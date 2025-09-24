TF_DIR=terraform
ENV?=dev

init:
	cd $(TF_DIR) && terraform init

plan:
	cd $(TF_DIR) && terraform workspace select $(ENV) || terraform workspace new $(ENV)
	cd $(TF_DIR) && terraform plan -var-file=envs/$(ENV).tfvars

apply:
	cd $(TF_DIR) && terraform workspace select $(ENV) || terraform workspace new $(ENV)
	cd $(TF_DIR) && terraform apply -var-file=envs/$(ENV).tfvars -auto-approve

destroy:
	cd $(TF_DIR) && terraform workspace select $(ENV) || terraform workspace new $(ENV)
	cd $(TF_DIR) && terraform destroy -var-file=envs/$(ENV).tfvars -auto-approve
