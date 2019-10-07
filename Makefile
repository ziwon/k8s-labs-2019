THIS_PATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_DIR := $(dir $(THIS_PATH))

KLAB = ./klab.sh
KEVENTS = kubectl get events

define HELM_PATCH
	kubectl create serviceaccount --namespace kube-system tiller
	kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	helm init --service-account tiller --upgrade
endef


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

.PHONY: helm-init helm-patch
helm-init:
	@helm init

helm-patch:
	$(subst $(CRLF), && ,$(HELM_PATCH))

helm-repo:
	helm repo add elastic https://helm.elastic.co

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

.PHONY: install-elasticsearch
install-elasticsearch:
	RELEASE_NAME=es; \
	REPLICAS=1; \
	MIN_REPLICAS=1; \
	STORAGE_CLASS=local-path; \
	helm install \
	  stable/elasticsearch \
      --name $${RELEASE_NAME} \
      --set client.replicas=$${MIN_REPLICAS} \
      --set master.replicas=$${REPLICAS} \
      --set master.persistence.storageClass=$${STORAGE_CLASS} \
      --set data.replicas=$${MIN_REPLICAS} \
      --set data.persistence.storageClass=$${STORAGE_CLASS} \
      --set master.podDisruptionBudget.minAvailable=$${MIN_REPLICAS} \
      --set cluster.env.MINIMUM_MASTER_NODES=$${MIN_REPLICAS} \
      --set cluster.env.RECOVER_AFTER_MASTER_NODES=$${MIN_REPLICAS} \
      --set cluster.env.EXPECTED_MASTER_NODES=$${MIN_REPLICAS};

.PHONY: events
events-desc: ## events sorting by last seen time
	@$(KEVENTS) --sort-by='.metadata.creationTimestamp'  -o 'go-template={{range .items}}{{.firstTimestamp}}{{"\t"}}{{.involvedObject.name}}{{"\t"}}{{.involvedObject.kind}}{{"\t"}}{{.message}}{{"\t"}}{{.reason}}{{"\t"}}{{.type}}{{"\t"}}{{"\n"}}{{end}}'

ifeq (events-type,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
events-type: ## events warning only
	@$(KEVENTS) --field-selector type=$(RUN_ARGS)

events-no-pod:
	@$(KEVENTS) --field-selector involvedObject.kind!=Pod

ifeq (events-any,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
events-any:
	@$(KEVENTS) --field-selector involvedObject.name=$(RUN_ARGS) --all-namespaces

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


.PHONY: up
up:
	@$(KLAB) up

.PHONY: down
down:
	@$(KLAB) down
down:

.DEFAULT_GOAL := help
