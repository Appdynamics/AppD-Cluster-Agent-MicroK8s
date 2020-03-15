#!/bin/bash
#
#
CMD_LIST=${1:-"help"}

export KUBECTL_CMD="microk8s.kubectl"

_Ubuntu_Update() {
  # Update Ubuntu - quiet install, non noninteractive
  sudo apt-get update
  DEBIAN_FRONTEND=noninteractive sudo apt-get -yqq upgrade
  DEBIAN_FRONTEND=noninteractive sudo apt-get -yqq install zip
}


_DockerCE_Install() {
  # Install Docker CE V19+ for Ubuntu
  # https://docs.docker.com/install/linux/docker-ce/ubuntu/

  # Install DockerCE
  sudo apt install -yqq apt-transport-https ca-certificates curl software-properties-common
  curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo apt-key add -
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
  sudo add-apt-repository "deb [arch=amd64] https://download.docker.com/linux/ubuntu bionic stable"
  apt-cache policy docker-ce
  sudo apt -yqq install docker-ce

  # Validate Docker Version and status
  docker version
  sudo usermod -aG docker ${USER}
  sudo systemctl status docker

  # Pull Ubuntu Docker image into local repository
  docker pull ubuntu
  docker images
  docker search ubuntu
}


_MicroK8s_Install() {
  # Install Canonical microk8s
  # https://microk8s.io/

  # Update snap
  sudo snap refresh
  sudo snap version

  # Install MicroK8s
  sudo snap install microk8s
  snap list
  microk8s.start
  sudo microk8s.status --wait-ready
  microk8s.status

  # Need to exit shell/ssh session for the following command to take effect
  sudo usermod -a -G microk8s ubuntu
  echo "Exit shell/ssh session and re-enter"
}


_MicroK8s_Start() {
  # Start and enable services on MicoK8s
  # https://microk8s.io/docs/commands
  microk8s.start

  # Enable DNS service
  microk8s.enable dns

  # Enable metrics-server - enables K8s metric collection APIs
  microk8s.enable metrics-server

  # Enable the default K8s Dashboard service
  #microk8s.enable dashboard

  # View services and pods
  microk8s.kubectl get services --all-namespaces
  microk8s.kubectl get pods --all-namespaces
}


_AppDynamics_Install_ClusterAgent() {

  # Set the controller access Key
  export APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY="xyzxyz"

  # Edit  cluster-agent.yaml
  # Modify  appName, controllerUrl, account
  # Set  image: "docker.io/appdynamics/cluster-agent:4.5.16"
  # Add additional namespaces to monitor under nsToMonitor:

  kubectl create namespace appdynamics

  kubectl get namespace

  kubectl create -f cluster-agent-operator.yaml

  kubectl -n appdynamics get pods

  kubectl -n appdynamics create secret generic cluster-agent-secret \
          --from-literal=controller-key=$APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY
  # kubectl -n appdynamics delete secret cluster-agent-secret

  # Start the cluster agent
  kubectl create -f cluster-agent.yaml

  # Stop the cluster agent
  kubectl delete -f cluster-agent.yaml
}

# Define the namespace and list of K8s resources to deploy into that namespace
ALL_NS_LIST=("namespace-test")
ALL_RUN_LIST=("alpine1" "alpine2" "busyboxes1" "busyboxes2")

# Execute command
case "$CMD_LIST" in
  ubuntu-update)
    _Ubuntu_Update
    ;;
  docker-install)
    _DockerCE_Install
    ;;
  k8s-install)
    _MicroK8s_Install
    ;;
  k8s-start)
    _MicroK8s_Start
    ;;
  pods-create)
    # Create the namespace: test
    for K8S_RESOURCE in "${ALL_NS_LIST[@]}"; do
      $KUBECTL_CMD create -f pods/$K8S_RESOURCE.yaml
    done
    # Create the pods
    for K8S_RESOURCE in "${ALL_RUN_LIST[@]}"; do
      $KUBECTL_CMD create -f pods/$K8S_RESOURCE.yaml
    done
    ;;
  pods-delete)
    # Delete the pods
    for K8S_RESOURCE in "${ALL_RUN_LIST[@]}"; do
      $KUBECTL_CMD delete -f pods/$K8S_RESOURCE.yaml
    done
    # Delete the namespace
    for K8S_RESOURCE in "${ALL_NS_LIST[@]}"; do
      $KUBECTL_CMD delete -f pods/$K8S_RESOURCE.yaml
    done
      ;;
  k8s-delete-all)
    $KUBECTL_CMD -n default delete pod,svc --all
    ;;
  k8s-log-dns)
    $KUBECTL_CMD logs --follow -n kube-system --selector 'k8s-app=kube-dns'
    ;;
  k8s-restart)
    sudo snap disable microk8s
    sudo snap enable microk8s
    ;;
  appd-install-cluster-agent)
    _AppDynamics_Install_ClusterAgent
    ;;
  services)
    $KUBECTL_CMD get services --all-namespaces -o wide
    ;;
  ns)
    $KUBECTL_CMD get all --all-namespaces
    ;;
  del-force)
    docker rmi $(docker images -q) -f
    docker system prune --all --force
    ;;
  k8s-metrics)
    microk8s.enable get --raw /apis/metrics.k8s.io/v1beta1/pods
    ;;
  dashboard-token)
    token=$(microk8s.kubectl -n kube-system get secret | grep default-token | cut -d " " -f1)
    microk8s.kubectl -n kube-system describe secret $token
    # kc proxy
    # ssh -N -L 8888:localhost:8001 r-apps
    # http://localhost:8888/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/#!/login
    ;;
  test)
    echo "Test"
    ;;
  help)
    echo "ubuntu-update, docker-install, k8s-install, k8s-start"
    ;;
  *)
    echo "Not Found " "$@"
    ;;
esac
