#
# .bash_aliases

# MicroK8s
#
alias kubectl="microk8s.kubectl "
alias kc="microk8s.kubectl "

# Get all pods and services across all namespaces
alias kc.ga="microk8s.kubectl   get all           --all-namespaces "
alias kc.list="microk8s.kubectl get pods,services --all-namespaces "
alias kc.pods="microk8s.kubectl get pod           --all-namespaces "
alias kc.srv="microk8s.kubectl get services       --all-namespaces "
