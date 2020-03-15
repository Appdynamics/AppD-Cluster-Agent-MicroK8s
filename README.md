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


