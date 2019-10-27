# k8s-labs

```sh
Personal Kubernetes Labs (yngpil.yoon@gmail.com)

Usage:
  make <target>
  tools                           Install tools to your local machine
  kubeconfig                      Get kubeconfig path
  helm-init                       Install helm
  helm-repo                       Install helm repo
  get-cert-manager                Install cert-manager
  get-traefik                     Install traefik components in order
  get-prometheus                  Install promethus operator from helm chart
  get-elasticsearch               Install elasticsearch
  events-desc                     Get events sorted by last seen time (ex. make events-desc)
  events-type                     Get events by type (ex. make events-type [Warning|Normal|...])
  events-any                      Get events with given object name (ex. make events-any traefik)
  k8s-create                      Create K3s Cluster
  k8s-delete                      Delete K3s Cluster
  k8s-up                          Start K3s cluster
  k8s-down                        Stop K3s cluster
  shell-node                      Get node shell into the given node
  shell-pod                       Get testing pod shell from k8s current context
  shell-docker                    Get docker shell
  sys-clean-all                   Clean up all docker resources
  host-add                        Add `$CLUSTER_DOMAIN` host to /etc/hosts
  host-remove                     Remove `$CLUSTER_DOMAIN` host from /etc/hosts
  help                            Show this help (default target)
```

