RKE Deployment
==============

1. Clone cluster-ansible-aio.

Command:

    git clone https://github.com/blallau/cluster-ansible-aio
    cd cluster-ansible-aio

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

    ./cluster-ansible-aio create-virtual-nodes

3. Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

Command:

    ./cluster-ansible-aio nodes-bootstrap

4. Bootstrap Docker in virtual nodes.

Command:

    ./cluster-ansible-aio docker-bootstrap

5. Launch RKE.

Command:

     ./rke_linux-amd64 up

6. Load Kubernetes config.

Command:

    export  KUBECONFIG=<PATH>/kube_config_cluster.yml

Kubernetes deployment
--------------------

7. Install Helm.

Command:

    helm init
    helm repo update

8. Give rights to Helm.

Command:

    kubectl create serviceaccount --namespace kube-system tiller
    kubectl create clusterrolebinding tiller-cluster-rule --clusterrole=cluster-admin --serviceaccount=kube-system:tiller
    kubectl patch deploy --namespace kube-system tiller-deploy -p '{"spec":{"template":{"spec":{"serviceAccount":"tiller"}}}}'
    helm init --service-account tiller --upgrade

9. Add Service Catalog.

Command:

    helm repo add svc-cat https://svc-catalog-charts.storage.googleapis.com
    helm search service-catalog
    helm install svc-cat/catalog --name catalog --namespace catalog

10. Add Service Catalog client.

Command:

    curl -sLO https://download.svcat.sh/cli/latest/linux/amd64/svcat
    chmod +x ./svcat
    mv ./svcat /usr/local/bin/
    svcat version --client

11. Add ROOK.

Command:

    helm repo add rook-alpha http://charts.rook.io/alpha
    helm install --name rook --namespace rook rook-alpha/rook

12. Add ES operator.

Command:

    helm repo add es-operator https://raw.githubusercontent.com/upmc-enterprises/elasticsearch-operator/master/charts/
    helm install --name elasticsearch-operator es-operator/elasticsearch-operator --set rbac.enabled=True --namespace logging
    helm install --name elasticsearch es-operator/elasticsearch --set kibana.enabled=True --set cerebro.enabled=True --set zones="{eu-west-1a,eu-west-1b}" --namespace logging

Clean-up
--------

Clean-up hypervisor and remove virtual nodes.

    ./cluster-ansible-aio remove-virtual-nodes --yes-i-really-really-mean-it
