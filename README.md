# AppDynamics Cluster Agent Lab for MicroK8s

This lab provides the steps and automation to deploy the AppDynamics Cluster Agent into a MicroK8s cluster in minutes

# MicroK8s

Provides a simple and fast installation of fully-conformant Kubernetes.
Read more: https://microk8s.io/

# Getting started

This lab is designed to run on Ubuntu, using MicroK8s and Docker CE

git clone https://github.com/APPDRYDER/AppD-Cluster-Agent-MicroK8s.git

`cd AppD-Cluster-Agent-Microk8s`

# AppDynamics Cluster agent

Download the cluster agent from: https://download.appdynamics.com/download/#version=&apm=cluster-agent&os=&platform_admin_os=&appdynamics_cluster_os=&events=&eum=&page=1

This will download the zip archive: appdynamics-cluster-agent-ubuntu-4.5.16.780.zip

# Install the AppDynamics Cluster Agent

In the directory: AppD-Cluster-Agent-Microk8s unzip the cluster:

`unzip appdynamics-cluster-agent-ubuntu-4.5.16.780.zip -d cluster-agent`

# Configure the Cluster Agent

In the cluster directory, modify the cluster-agent.yaml

`cd cluster-agent`

Edit cluster-agent.yaml

Modify the fields:

````
appName: "<app-name>"
controllerUrl: "http://<appdynamics-controller-host>:8080"
account: "<account-name>"
````


Add an aditonal namespaces to monitor. Add the field nsToMonitor and the namesSpaces:
````
  nsToMonitor:
    test
    default
    appdynamics
    kube-system
````

# Update Ubuntu Operating System, install and configure MicroK8s Kubernetes Cluster:

In the directory: AppD-Cluster-Agent-Microk8s run the following commands using the script ctl.sh:

### Update Ubuntu
````./ctl.sh ubuntu-update````

### Install Docker Communit Edition
````./ctl.sh docker-install````

### Install MicroK8s
````./ctl.sh k8s-install````

### Start the MicroK8s Kubernetes Cluster
````./ctl.sh k8s-start````

# Deploy Pods to the MicroK8s Kubernetes Cluster

In the directory: AppD-Cluster-Agent-Microk8s run the following commands using the script ctl.sh:

````./ctl.sh pods-create````

The above command will create a namespace called "test" and deploy two pods (alpine1,alpine2) with single containers, and two services (busyboxes1, busyboxes2) each with two containers.

Review the K8s resource definitions in the directory pods for details of these resources.

Rewview what services, pods, namesspaces are running in the cluster using the command:

````microk8s.kubectl get pods,services --all-namespaces````




# NEXT
