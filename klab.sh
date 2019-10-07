#!/bin/bash

set -e -uo pipefail

CURRENT_DIR="$(cd "$(dirname "${0}")" && pwd -P)"

source .envrc


init() {
  k3d create \
    --name "$CLUSTER_NAME" \
    --image "$K3S_IMAGE" \
    --workers "3" \
    --publish "8081:80" \
    --publish "8443:443" \
    --publish "8080:8080" \
    --server-arg "--no-deploy=traefik" \
    --server-arg "--no-deploy=cert-manager"

  echo ">> Waiting for cluster to get ready..."
  sleep 10

  KUBECONFIG="$(k3d get-kubeconfig --name="${CLUSTER_NAME}")"
  export KUBECONFIG

  # Install local-path-storage
  kubectl --kubeconfig="${KUBECONFIG}" apply -f "addons/local-path-storage.yaml"
  kubectl --kubeconfig="${KUBECONFIG}" patch storageclass local-path -p '{"metadata": {"annotations":{"storageclass.kubernetes.io/is-default-class":"true"}}}'

  # Install cert-manager
  kubectl --kubeconfig="${KUBECONFIG}" apply -f "https://raw.githubusercontent.com/jetstack/cert-manager/release-0.8/deploy/manifests/00-crds.yaml"
  kubectl --kubeconfig="${KUBECONFIG}" apply -f "addons/cert-manager.yaml"

  # Install cluster issuers
  kubectl --kubeconfig="${KUBECONFIG}" apply -f "issuers/cluster-issuer-prod.yaml"
  kubectl --kubeconfig="${KUBECONFIG}" apply -f "issuers/cluster-issuer-staging.yaml"

  # Install metrics
  git clone https://github.com/kubernetes-incubator/metrics-server.git
  kubectl apply -f metrics-server/deploy/1.8+/
  rm -rf metrics-server

  echo ">> Your k3s cluster ready"

  exit 0
}

up() {
  k3d start --name ${CLUSTER_NAME}
}

down() {
  k3d stop --name ${CLUSTER_NAME}
}

boot_docker() {
  set -e
  docker system info > /dev/null 2>&1;
  if [ $? -ne 0 ]; then
    open --background -a Docker && echo -n "Docker is starting..";
    while ! docker system info > /dev/null 2>&1; do echo -e ".\c"; sleep 1; done;
    echo -e "done.\n"
  fi
  set +e
}

case $1 in
  up)
    boot_docker
    up
    hash direnv &> /dev/null && direnv allow || echo "Please, install direnv."
    ;;

  down)
    down
    ;;

  *)
    echo "Unknown: $1"; exit 1;
    ;;
esac
