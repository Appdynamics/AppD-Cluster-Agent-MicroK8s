#!/bin/bash
#
# AppDynmaics Cluster Agent Automation Script for MicroK8s kubernetes
#
# Maintainer: David Ryder, david.ryder@appdynamics.com
#
#
CMD_LIST=${1:-"help"}

export KUBECTL_CMD="microk8s.kubectl"
export CLUSTER_AGENT_DIR="cluster-agent"

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
  # Need to exit shell/ssh session for the following command to take effect
  sudo usermod -aG docker ${USER}
  echo ""
  echo ">>>> Exit current session: shell/ssh, and re-enter for previous usermod command to work <<<<"

  # Validate Docker Version and status
  #docker version

  #sudo systemctl status docker

  # Pull Ubuntu Docker image into local repository
  #docker pull ubuntu
  #docker images
  #docker search ubuntu
}


_MicroK8s_Install() {
  # Install Canonical microk8s
  # https://microk8s.io/

  # Update snap
  sudo snap refresh
  sudo snap version

  # Install MicroK8s
  sudo snap install microk8s --classic
  snap list
  sudo microk8s.start
  sudo microk8s.status --wait-ready
  sudo microk8s.status

  # Need to exit shell/ssh session for the following command to take effect
  sudo usermod -a -G microk8s ubuntu
  #newgrp microk8s # fix exit shell?
  echo ""
  echo ">>>> Exit current session: shell/ssh, and re-enter for previous usermod command to work <<<<"
}


_MicroK8s_Start() {
  # Start and enable services on MicoK8s
  # https://microk8s.io/docs/commands

  # Make sure session restarted for  'sudo usermod -a -G microk8s ubuntu' to work
  microk8s.kubectl version >> /dev/null
  if [ $? == 1 ]; then
    echo ">>>> Exit current session: shell/ssh, and re-enter for previous usermod command to work <<<<"
    exit 1
  fi

  microk8s.start

  # Enable DNS service
  sudo microk8s.enable dns

  # Enable metrics-server - enables K8s metric collection APIs
  sudo microk8s.enable metrics-server

  # Enable the default K8s Dashboard service
  #microk8s.enable dashboard

  # View services and pods
  sudo microk8s.kubectl get services --all-namespaces
  sudo microk8s.kubectl get pods --all-namespaces
}


_AppDynamics_Install_ClusterAgent() {
  K8S_OP=${1:-"replace"}

  # Set the controller access Key
  #export APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY="xyzxyz"
  _validateEnvironmentVars "AppDynamics Controller" "APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY"

  # Edit  cluster-agent.yaml
  # Modify  appName, controllerUrl, account
  # Set  image: "docker.io/appdynamics/cluster-agent:4.5.16"
  # Add additional namespaces to monitor under nsToMonitor:

  if [[ -d "$CLUSTER_AGENT_DIR" ]]; then
    $KUBECTL_CMD create namespace appdynamics

    $KUBECTL_CMD get namespace

    # Note use of replace
    $KUBECTL_CMD $K8S_OP -f $CLUSTER_AGENT_DIR/cluster-agent-operator.yaml

    $KUBECTL_CMD -n appdynamics get pods

    $KUBECTL_CMD --namespace=appdynamics delete secret cluster-agent-secret
    sleep 5 # Allow Time for delete

    $KUBECTL_CMD --namespace=appdynamics create secret generic cluster-agent-secret \
                 --from-literal=controller-key="$APPDYNAMICS_AGENT_ACCOUNT_ACCESS_KEY"
    sleep 5 # Allow time for create

    $KUBECTL_CMD get secrets --namespace=appdynamics

    # Start the cluster agent
    $KUBECTL_CMD $K8S_OP -f $CLUSTER_AGENT_DIR/cluster-agent.yaml

    # Stop the cluster agent
    #kubectl delete -f cluster-agent.yaml
  else
    echo "could not find Cluster Agent directory: ($CLUSTER_AGENT_DIR)"
    echo "Current directory is `pwd`"
    echo "Expected `pwd`/$CLUSTER_AGENT_DIR"
  fi
}

_AppDynamics_Delete_ClusterAgent() {
  $KUBECTL_CMD delete -f $CLUSTER_AGENT_DIR/cluster-agent.yaml
  $KUBECTL_CMD delete -f $CLUSTER_AGENT_DIR/cluster-agent-operator.yaml
  $KUBECTL_CMD --namespace=appdynamics delete secret cluster-agent-secret
  $KUBECTL_CMD delete namespace appdynamics
}


_validateEnvironmentVars() {
  echo "Validating environment variables for $1"
  shift 1
  VAR_LIST=("$@") # rebuild using all args
  #echo $VAR_LIST
  for i in "${VAR_LIST[@]}"; do
    echo "$i=${!i}"
    if [ -z ${!i} ] || [[ "${!i}" == REQUIRED_* ]]; then
       echo "Please set the Environment variable: $i"; ERROR="1";
    fi
  done
  [ "$ERROR" == "1" ] && { echo "Exiting"; exit 1; }
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
  appd-create-cluster-agent)
    _AppDynamics_Install_ClusterAgent "create"
    ;;
  appd-replace-cluster-agent)
    _AppDynamics_Install_ClusterAgent "replace"
    ;;
  appd-delete-cluster-agent)
    _AppDynamics_Delete_ClusterAgent
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
  group-remove)
    # Testing
    sudo gpasswd -d $USER microk8s
    sudo gpasswd -d $USER docker
    ;;
  test)
    echo "Test"
    ;;
  help)
    echo "ubuntu-update, docker-install, k8s-install, k8s-start, pods-create, appd-install-cluster-agent"
    ;;
  *)
    echo "Not Found " "$@"
    ;;
esac
