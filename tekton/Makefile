SHELL := /bin/bash

TEKTON_CLI_VERION := 0.4.0
TEKTON_DASHBOARD_VERSION := 0.2.0
ISTIO_VERSION := 1.1.7
KNATIVE_VERSION := 0.8.0

DOCKER_SECRET_FILE = secrets/docker-secret.yaml
GITHUB_SECRET_FILE = secrets/git-secret.yaml

.PHONY: help
help: ## Show the usage (default target)
	@echo -e "Cloud Native CI/CD with Tekton (yngpil.yoon@gmail.com)\n"
	@awk 'BEGIN { \
		FS=":.*##"; \
		printf "Usage:\n  make \033[33m<target>\033[0m\n" \
	} \
	/^[a-zA-Z0-9_-]+:.*?##/ { printf "  \033[1;33m%-30s\033[0m %s\n", $$1, $$2 } \
	/^@##.*?/ { printf "\n\033[1m%s\033[0m\n", $$1 }' $(MAKEFILE_LIST)


PHONY: tekton-install tekton-install-tkn
tekton-install: ## Install the latest Tekton and Tekton Dashboard into your cluster
	@kubectl apply -f https://storage.googleapis.com/tekton-releases/latest/release.yaml
	@kubectl apply -f https://github.com/tektoncd/dashboard/releases/download/v${TEKTON_DASHBOARD_VERSION}/release.yaml

tekton-install-tkn: ## Install the `tkn` CLI into your OS X machine
	@curl -sLO https://github.com/tektoncd/cli/releases/download/v${TEKTON_CLI_VERION}/tkn_${TEKTON_CLI_VERION}_Darwin_x86_64.tar.gz
	@sudo tar xvzf tkn_${TEKTON_CLI_VERION}_Darwin_x86_64.tar.gz -C /usr/local/bin/ tkn

.PHONY: tekton-tasks tekton-runs tekton-dashboards
tekton-tasks: ## Show all Tekton task definitions
	@echo -e "Tasks"
	@kubectl get tasks -n tekton-pipelines
	@echo -e "\nPipelines"
	@kubectl get pipelines -n tekton-pipelines
	@echo -e "\nPipeline Resources"
	@kubectl get pipelineresources -n tekton-pipelines

tekton-runs: ## Show all Tekton runs
	@echo -e "Task Runs"
	@kubectl get taskruns -n tekton-pipelines
	@echo -e "\nPipleline Runs"
	@kubectl get pipelineruns -n tekton-pipelines

tekton-dashboard: # Open Tekton dashboard by port-forwarding
	@pkill kubectl 2>/dev/null || true
	@kubectl port-forward -n tekton-pipelines service/tekton-dashboard 8080:9097 >> /dev/null &


.PHONY: task-hello-world task-run-hello-world
task-hello-world: ## Define a simple task that will echo "hello world"
	@kubectl apply -f tasks/hello-world.yaml
	@echo -e "Task List"
	@tkn task list

task-run-hello-world: ## Execute a simple task that defined as 'echo-hello-world' Task
	@kubectl apply -f taskruns/hello-world.yaml
	@echo -e "TaskRun List"
	@tkn taskrun list

task-build-go-app: ## Create go-app resources to be defined for go-app, and execute build-push task
	@kubectl delete taskruns.tekton.dev build-go-app-docker $^ 2>/dev/null; true;
	@kubectl apply -f resources/git-go-app.yaml
	@kubectl apply -f resources/img-go-app.yaml
	@kubectl apply -f tasks/build-docker-image-from-git-source.yaml
	@kubectl apply -f taskruns/build-go-app-docker.yaml
	@echo -e "TaskRun List"
	@watch tkn taskrun list
	@sleep 2
	@open https://hub.docker.com/r/ziwon/go-app &


task-build-go-app-kaniko: ## Build go-app with using a Task from the Tekton Catalog
	@echo -e "Install kanino Task"
	@kubectl apply -f https://raw.githubusercontent.com/tektoncd/catalog/master/kaniko/kaniko.yaml
	@echo -e "\nExecute build task using kaniko"
	@kubectl apply -f  taskruns/build-go-app-using-kaniko-catalog.yaml
	@echo -e "\nTaskRun List"
	@tkn taskrun list
	@sleep 2
	@open https://hub.docker.com/r/ziwon/go-app


.PHONY: tekton-install-webhook
tekton-install-webhook: ## Create resources for Tekton Triggers
	@bash -c "./scripts/install_istio.sh $(ISTIO_VERSION)"
	@bash -c "./scripts/install_knative.sh v$(KNATIVE_VERSION)"
	@kubectl apply --filename https://github.com/tektoncd/dashboard/releases/latest/download/webhooks-extension_release.yaml


task-deploy-go-app: k8s-service-accounts tekton-dashboard ## Deploy go-app with build-push-deploy pipelines and its pipelines
	@echo -e "Create service account"
	@kubectl apply -f resources/git-go-app.yaml
	@kubectl apply -f resources/img-go-app.yaml
	@kubectl apply -f tasks/build-docker-image-from-git-source.yaml
	@kubectl apply -f tasks/deploy-using-kubectl.yaml
	@kubectl apply -f pipelines/build-push-deploy.yaml
	@kubectl apply -f pipelineruns/go-app.yaml
	@echo -e "\nPipeLine List"
	@tkn pipelines list
	@echo -e "\nPipeLine Runs List"
	@tkn pipelineruns list
	@sleep 2
	@open http://tekton-dashboard.192.168.100.48.nip.io/#/namespaces/tekton-pipelines/pipelines/pipeline-go-app/runs/go-app &
	@tkn pipelineruns logs -f go-app


.PHONY: k8s-secrets k8s-service-accounts k8s-forward-svc
k8s-secrets: ## Create a Secret manifest, which is used to store your Docker Hub credentials
	source ./.secrets ;\
	enc(){ echo $$1 | sed 's/=//g' | xargs echo -n | base64; } ;\
	DOCKER_USERNAME=$$(enc $$DOCKER_USERNAME) ;\
	DOCKER_PASSWORD=$$(enc $$DOCKER_PASSWORD) ;\
	GITHUB_ACCESS_TOKEN=$$(enc $$GITHUB_ACCESS_TOKEN) ;\
	kubens tekton-pipelines ;\
	cat $(DOCKER_SECRET_FILE) | sed -e 's|{% DOCKER_USERNAME %}|'$$DOCKER_USERNAME'|;s|{% DOCKER_PASSWORD %}|'$$DOCKER_PASSWORD'|' | kubectl apply -f - $^ 2>/dev/null; true ;\
	cat $(GITHUB_SECRET_FILE) | sed -e 's|{% GITHUB_ACCESS_TOKEN %}|'$$GITHUB_ACCESS_TOKEN'|;s|{% GITHUB_WEBHOOK_SECRET %}|'$$GITHUB_WEBHOOK_SECRET'|' | kubectl apply -f - $^ 2>/dev/null; true ;\
	sleep 2 ;\
	echo -e "Secrets" ;\
	kubectl get secret ;

k8s-service-accounts: k8s-secrets
	@kubens tekton-pipelines
	@echo "Creating Docker bot..."
	@kubectl apply -f secrets/sa-docker-bot.yaml
	@kubectl apply -f roles/deploy-manager.yaml
	@kubectl apply -f roles/deploy-manager-docker-bot.yaml
	@echo -e "\nCreating CICD bot..."
	@kubectl apply -f secrets/sa-cicd-bot.yaml
	@kubectl apply -f roles/tekton-triggers-manager.yaml
	@kubectl apply -f roles/tekton-triggers-role-binding.yaml
	@sleep 2
	@echo -e "\nService Accounts"
	@kubectl get serviceaccounts

k8s-ingress:
	@$(eval HOST_IP:=$(shell ifconfig | grep netmask | sed -n 2p | cut -d ' ' -f2))
	@cat ./ingress/certificate-staging.yaml | sed -e 's|{% HOST_IP %}|$(HOST_IP)|' | kubectl apply -f -
	@cat ./ingress/ingress-tekton-dashboard.yaml | sed -e 's|{% HOST_IP %}|$(HOST_IP)|' | kubectl apply -f -

.DEFAULT_GOAL := help
