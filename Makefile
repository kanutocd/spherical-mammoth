SHELL := /bin/bash
COMPOSE := docker compose --file deployment/compose/compose.yaml
HELM_CHART := deployment/helm/spherical-mammoth

.PHONY: validate compose-config compose-up compose-down smoke-lifecycle helm-lint tofu-fmt tofu-validate kind-create kind-delete scaffold-check

validate: compose-config helm-lint tofu-fmt scaffold-check

compose-config:
	$(COMPOSE) config >/dev/null

compose-up:
	$(COMPOSE) up --build --wait

compose-down:
	$(COMPOSE) down

smoke-lifecycle:
	./scenarios/signup/run

helm-lint:
	helm lint $(HELM_CHART)

tofu-fmt:
	tofu -chdir=deployment/opentofu/aws fmt -check -recursive

tofu-validate:
	tofu -chdir=deployment/opentofu/aws init -backend=false
	tofu -chdir=deployment/opentofu/aws validate

kind-create:
	kind create cluster --config deployment/kind/cluster.yaml

kind-delete:
	kind delete cluster --name spherical-mammoth

scaffold-check:
	./scripts/check-scaffold
