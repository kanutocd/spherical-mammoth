SHELL := /bin/bash
COMPOSE := docker compose --file deployment/compose/compose.yaml
HELM_CHART := deployment/helm/spherical-mammoth

.PHONY: validate compose-config compose-up compose-down e2e-signup smoke-lifecycle helm-dependency-local helm-lint helm-template kind-create kind-delete kind-verify tofu-fmt tofu-validate packer-fmt packer-validate scaffold-check

validate: compose-config helm-lint tofu-fmt scaffold-check

compose-config:
	$(COMPOSE) config >/dev/null

compose-up:
	$(COMPOSE) up --build --wait

compose-down:
	$(COMPOSE) down

e2e-signup:
	./scenarios/signup/run

smoke-lifecycle: e2e-signup

helm-lint:
	helm lint $(HELM_CHART)

helm-dependency-local:
	./scripts/helm-dependency-local $(HELM_CHART)

helm-template: helm-dependency-local
	helm template spherical-mammoth $(HELM_CHART) --values $(HELM_CHART)/values-kind.yaml >/dev/null

tofu-fmt:
	tofu -chdir=deployment/opentofu/aws fmt -check -recursive
	tofu -chdir=deployment/opentofu/gcp fmt -check -recursive
	tofu -chdir=deployment/opentofu/poorman-aws fmt -check -recursive
	tofu -chdir=deployment/opentofu/poorman-k3s-aws fmt -check -recursive

tofu-validate:
	tofu -chdir=deployment/opentofu/aws init -backend=false
	tofu -chdir=deployment/opentofu/aws validate
	tofu -chdir=deployment/opentofu/gcp init -backend=false
	tofu -chdir=deployment/opentofu/gcp validate
	tofu -chdir=deployment/opentofu/poorman-aws init -backend=false
	tofu -chdir=deployment/opentofu/poorman-aws validate
	tofu -chdir=deployment/opentofu/poorman-k3s-aws init -backend=false
	tofu -chdir=deployment/opentofu/poorman-k3s-aws validate

packer-fmt:
	packer fmt -check deployment/opentofu/poorman-aws/packer
	packer fmt -check deployment/opentofu/poorman-k3s-aws/packer

packer-validate:
	packer init deployment/opentofu/poorman-aws/packer
	packer validate -var-file=deployment/opentofu/poorman-aws/packer/example.pkrvars.hcl deployment/opentofu/poorman-aws/packer
	packer init deployment/opentofu/poorman-k3s-aws/packer
	packer validate -var-file=deployment/opentofu/poorman-k3s-aws/packer/example.pkrvars.hcl deployment/opentofu/poorman-k3s-aws/packer

kind-create:
	kind create cluster --config deployment/kind/cluster.yaml

kind-delete:
	kind delete cluster --name spherical-mammoth

kind-verify:
	./scripts/kind-verify

scaffold-check:
	./scripts/check-scaffold
