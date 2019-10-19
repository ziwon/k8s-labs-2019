THIS_PATH:=$(abspath $(lastword $(MAKEFILE_LIST)))
THIS_DIR:=$(dir $(THIS_PATH))

K=kubectl
H=helm
KLAB=./klab.sh
KEVENTS=$(K) get events

define HELM_PATCH
	$(K) create serviceaccount --namespace kube-system tiller
	$(K) create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
	$(K) patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
	$(H) init --service-account tiller --upgrade
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

.PHONY: tools
tools: ## Install tools to your local machine
	@curl -s https://raw.githubusercontent.com/rancher/k3d/master/install.sh | bash
	@brew install kubectx
	@brew install stern
	@brew install octant
	@brew install derailed/k9s/k9s

.PHONY: kubeconfig
kubeconfig: ## Get kubeconfig path
	@echo "export KUBECONFIG=$$(k3d get-kubeconfig --name=$${CLUSTER_NAME})"

.PHONY: helm-init helm-patch
helm-init: ## Install helm
	@$(H) init
	$(subst $(CRLF), && ,$(HELM_PATCH))

.PHONY: helm-repo
helm-repo: ## Install helm repo
	$(H) repo add elastic https://helm.elastic.co
	$(H) repo add maesh https://containous.github.io/maesh/charts

.PHONY: get-cert-manager
get-cert-manager: ## Install cert-manager
	@$(K) --kubeconfig="${KUBECONFIG}" apply -f "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.9/deploy/manifests/00-crds.yaml"
	@$(K) --kubeconfig="${KUBECONFIG}" apply -f "addons/cert-manager.yaml"
	@$(K) --kubeconfig="${KUBECONFIG}" apply -f "issuers/cluster-issuer-prod.yaml"

.PHONY: get-traefik
get-traefik: ## Install traefik components in order
	@$(K) apply -f traefik/00-crds
	@$(K) apply -f traefik/01-accounts
	@$(K) apply -f traefik/02-deploy

.PHONY: get-mesh
get-mesh:
	@$(H) install --name=maesh --namespace=kube-system maesh/maesh

.PHONY: get-prometheus
get-prometheus: ## Install promethus operator from helm chart
	@cat ./prom-op/values.yaml | sed -e 's|$${CLUSTER_DOMAIN}|$(CLUSTER_DOMAIN)|' | $(H) install --debug --name monitoring --namespace kube-system stable/prometheus-operator -f -

.PHONY: update-prometheus
update-prometheus:
	helm upgrade -f prom-op/values.yaml monitoring stable/prometheus-operator

del-prometheus: del-prometheus-crd
	@$(H) delete monitoring --purge

del-prometheus-crd:
	@$(K) delete crd prometheuses.monitoring.coreos.com $^ 2>/dev/null; true;
	@$(K) delete crd prometheusrules.monitoring.coreos.com $^ 2>/dev/null; true;
	@$(K) delete crd servicemonitors.monitoring.coreos.com $^ 2>/dev/null; true
	@$(K) delete crd alertmanagers.monitoring.coreos.com $^ 2>/dev/null; true;
	@$(K) delete crd podmonitors.monitoring.coreos.com $^ 2>/dev/null; true;


.PHONY: get-elasticsearch
get-elasticsearch: helm-repo ## Install elasticsearch
	RELEASE_NAME=es; \
	REPLICAS=1; \
	MIN_REPLICAS=1; \
	STORAGE_CLASS=local-path; \
	$(H) install \
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

.PHONY: events-desc events-type events-any
events-desc: ## Get events sorted by last seen time (ex. make events-desc)
	@$(KEVENTS) --sort-by='.metadata.creationTimestamp'  -o 'go-template={{range .items}}{{.firstTimestamp}}{{"\t"}}{{.involvedObject.name}}{{"\t"}}{{.involvedObject.kind}}{{"\t"}}{{.message}}{{"\t"}}{{.reason}}{{"\t"}}{{.type}}{{"\t"}}{{"\n"}}{{end}}'

ifeq (events-type,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
events-type: ## Get events by type (ex. make events-type [Warning|Normal|...])
	@$(KEVENTS) --field-selector type=$(RUN_ARGS)

ifeq (events-any,$(firstword $(MAKECMDGOALS)))
  RUN_ARGS := $(wordlist 2,$(words $(MAKECMDGOALS)),$(MAKECMDGOALS))
  $(eval $(RUN_ARGS):;@:)
endif
events-any: ## Get events with given object name (ex. make events-any traefik)
	@$(KEVENTS) --field-selector involvedObject.name=$(RUN_ARGS) --all-namespaces

.PHONY: run-test-pod
run-test-pod: ## Deploy a pod for testing
	@$(K) run test --generator=run-pod/v1  --image=tutum/curl -- sleep 10000

.PHONY: create delete up down
k3s-create: ## Create K3s Cluster
	@$(KLAB) $@

k3s-delete: ## Delete K3s Cluster
	@$(KLAB) $@

k3s-up: ## Start K3s cluster
	@$(KLAB) $@

k3s-down: ## Stop K3s cluster
	@$(KLAB) $@

.PHONY: sys-clean-all
sys-clean-all: ## Clean up all docker resources
	docker system prune --all --force
	@sleep 10 # wait for a little to be removed all of the huge files

.DEFAULT_GOAL := help
