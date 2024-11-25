.PHONY: all help init init-upgrade cleanup fmt validate pve-api-user plan apply refresh show

ifneq (,$(wildcard ./.env))
sinclude .env
export
endif

all: help

help: ## Show this help
	@echo "Usage: make [target]"
	@echo "Targets:"
	@awk '/^[a-zA-Z0-9_-]+:.*?##/ { \
		helpMessage = match($$0, /## (.*)/); \
		if (helpMessage) { \
			target = $$1; \
			sub(/:/, "", target); \
			printf "  \033[36m%-20s\033[0m %s\n", target, substr($$0, RSTART + 3, RLENGTH); \
		} \
	}' $(MAKEFILE_LIST)


init:  ## Init environment of Ansible, and Terraform
	@terraform version
	@ansible --version
	@pip install --no-cache-dir -r requirements.txt
	@cd ansible; ansible-galaxy role install -r requirements.yml; ansible-galaxy collection install --no-cache -r requirements.yml
	@cd terraform; terraform init

init-upgrade:  ## Init/upgrade environment of Ansible, and Terraform
	@terraform version
	@ansible --version
	@pip install --no-cache-dir -U -r requirements.txt
	@cd ansible; ansible-galaxy role install --force -r requirements.yml; ansible-galaxy collection install --force --no-cache -r requirements.yml
	@cd terraform; terraform init -upgrade

cleanup:  ## Cleanup environment of Ansible, and Terraform
	@rm -rf ~/.ansible/roles
	@rm -rf ~/.ansible/collections
	@rm -rf terraform/.terraform

fmt:  ## Format Terraform files
	@cd terraform; terraform fmt

validate:  ## Validate Terraform files, lint Ansible files
	@cd ansible; ansible-lint
	@cd terraform; terraform validate

pve-api-user:  ## Create Proxmox API user Terraform
	@cd ansible; ansible-playbook pve_api_user.yml -e "pve_host=${PROXMOX_NODE}"

# stage0-build:  ## Build stage0 Proxmox template from cloud-init image
# 	@cd ansible; ansible-playbook pve_template_build.yml -e "pve_host=${PROXMOX_NODE}"

# stage0-destroy:  ## Destroy stage0 template
# 	@cd ansible; ansible-playbook pve_template_destroy.yml -e "pve_host=${PROXMOX_NODE}" -e "pve_template_vmid=${STAGE0_VM_ID}"

# stage0-build-force: stage0-destroy  ## Recreate (Destroy + Build) stage0 template
# 	@make stage0-build --no-print-directory

plan:  ## [terraform] Show changes required by the current configuration
	@cd terraform; terraform plan

apply:  ## [terraform] Create or update infrastructure
	@cd terraform; terraform apply && terraform refresh

refresh:  ## [terraform] Update the state to match remote systems
	@cd terraform; terraform refresh

show:  ## [terraform] Show the current state or a saved plan
	@cd terraform; terraform show