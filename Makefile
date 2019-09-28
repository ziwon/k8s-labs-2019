THIS_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_DIR := $(dir $(THIS_PATH))

.DEFAULT_GOAL := help

.PHONY: help
help: ## Show this help (default target)
	@echo "Cloud Native CI/CD with Tekton (yngpil.yoon@gmail.com)\n"
	@awk 'BEGIN { \
		FS=":.*##"; \
		printf "Usage:\n  make \033[33m<target>\033[0m\n" \
	} \
	/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[1;33m%-30s\033[0m %s\n", $$1, $$2 } \
	/^@##.*?/ { printf "\n\033[1m%s\033[0m\n", $$1 }' $(MAKEFILE_LIST)

.PHONY:
delete-pod:
	@kubectl -lapp=(TAG)


.PHONY: install-cert-manager
install-cert-manager: ## Install cert-manager
	@kubectl --kubeconfig="${KUBECONFIG}" apply -f "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml"
	@kubectl --kubeconfig="${KUBECONFIG}" apply -f "addons/cert-manager.yaml"
	@kubectl --kubeconfig="${KUBECONFIG}" apply -f "issuers/cluster-issuer-prod.yaml"


.PHONY: install-traefik
install-traefik: ## Install traefik
	@kubectl apply -f traefik/00-crds
	@kubectl apply -f traefik/01-accounts
	@kubectl apply -f traefik/02-deploy

.PHONY: watch-events
watch-events: ## Watch events sorting by last seen time
	@watch kubectl get events --sort-by='.lastTimestamp'

.PHONY: run-test-pod
run-test-pod:
	@kubectl run test --generator=run-pod/v1  --image=tutum/curl -- sleep 10000

.PHONY: clean-all
clean-all:
	docker system prune --all --force
	@sleep 10 # wait for a little to be removed all of the huge files

.PHONY: logs
ifeq (logs,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
logs: # Show logs
	@$(eval POD_NAME := $(shell [[ "$(RUN_ARGS)" = "${str%[[:space:]]*}" ]] && cut -d ' ' -f1 || echo "$(RUN_ARGS)" ))
	@$(eval NAMESPACE := $(shell {  [[ "$(RUN_ARGS)" = "${str%[[:space:]]*}" ]] && cut -d ' ' -f2 } || kubectl config view --minify --output 'jsonpath={..namespace}'))
	kail -lapp=$(POD_NAME) -n $(NAMESPACE)
