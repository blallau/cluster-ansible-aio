Cluster-ansible-aio
===================

Multi-node deployment of cluster system (Kolla, oVirt, RKE, OpenShift) using Libvirt and Ansible.

![kolla-ansible-aio](https://user-images.githubusercontent.com/9655027/31175714-6e453b1e-a910-11e7-8a60-f7c6d2114b1a.png)

Kolla-ansible-aio is an open source tool for automating deployment of
Openstack Kolla-ansible in multi-node scenario, on a single machine.

Kolla-ansible-aio is composed of Ansible playbooks, and makes heavy use
of Libvirt, OpenStack Kolla and Kolla-ansible project.

Kolla-ansible-aio aims to test, use and develop on Kolla and
Kolla-ansible projects.

-   Source: <https://github.com/blallau/kolla-ansible-aio>

Features
--------

-   Multi-node (1 master and Nx nodes)
-   Multi OS (CentOS and Ubuntu compliancy)
-   Heavily automated using Ansible
-   Quick deployment: using PIP cache proxy (Devpi) and APT cache proxy (apt-cacher-ng)

Quickstart guide
----------------

Install dependencies
--------------------

Make sure the PIP package manager is installed and upgraded to the latest version:

```
#CentOS
sudo yum install epel-release
sudo yum install python-pip
sudo pip install -U pip

#Ubuntu
sudo apt-get update
sudo apt-get install python-pip
sudo pip install -U pip
```

Install dependencies needed to build the code with PIP package manager:

```
#CentOS
sudo yum install python-devel libffi-devel gcc openssl-devel libselinux-python

#Ubuntu
sudo apt-get install python-dev libffi-dev gcc libssl-dev python-selinux
```

Install Ansible (>= 2.4) using PIP:

```
#CentOS & Ubuntu
sudo pip install -U ansible
```

Deployment RKE
--------------

1. Clone kolla-ansible-aio.

Command:

    git clone https://github.com/blallau/kolla-ansible-aio
    cd kolla-ansible-aio

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

    ./kolla-ansible-aio create-virtual-nodes

3. Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

Command:

    ./kolla-ansible-aio nodes-bootstrap

4. Bootstrap Docker in virtual nodes.

Command:

    ./kolla-ansible-aio docker-bootstrap

5. Launch RKE.

Command:

     ./rke_linux-amd64 up

6. Load Kubernetes config.

Command:

    export  KUBECONFIG=<PATH>/kube_config_cluster.yml

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

Deployment oVirt
----------------

1. Clone kolla-ansible-aio.

Command:

    git clone https://github.com/blallau/kolla-ansible-aio
    cd kolla-ansible-aio

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

    ./kolla-ansible-aio create-virtual-nodes

3. Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

Command:

    ./kolla-ansible-aio nodes-bootstrap -e nested_virt_enabled=true

4. Deploy oVirt.

Command:

    ./kolla-ansible-aio ovirt-deploy

4. Populate oVirt.

Command:

    ./kolla-ansible-aio ovirt-populate

Deployment OpenShift
--------------------

1. Clone kolla-ansible-aio.

Command:

    git clone https://github.com/blallau/kolla-ansible-aio
    cd kolla-ansible-aio

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

Command:

    ./kolla-ansible-aio create-virtual-nodes -e vm_os_distro=centos

3. Bootstrap OpenShift.

Command:

    ansible-playbook -i ../OPENSHIFT/openshift-ansible/inventory/hosts prepare.yml
    ansible-playbook -i ../OPENSHIFT/openshift-ansible/inventory/deploy_cluster.yml

Deployment Kolla
----------------

1. Clone kolla-ansible-aio.

Command:

    git clone https://github.com/blallau/kolla-ansible-aio
    cd kolla-ansible-aio

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

    ./kolla-ansible-aio create-virtual-nodes

Virtual nodes OS can be override using **vm_os_distro** variable.

Example: in case of Ubuntu hypervisor and CentOS virtual nodes wanted.

    ./kolla-ansible-aio create-virtual-nodes -e vm_os_distro=centos

Any of the default role variables can be easily overridden with variables from **group_vars/all.yml**

3. Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

Command:

    ./kolla-ansible-aio nodes-bootstrap

4. Bootstrap Kolla nodes.

Command:

    ./kolla-ansible-aio kolla-bootstrap

5. Build Kolla Docker images.

Command:

    ./kolla-ansible-aio kolla-build [-e install_type=binary] [-e kolla_build_profile=default]

6. Deploy multi-node Openstack using Kolla-ansible.

Command:

    ./kolla-ansible-aio kolla-ansible-deploy

Clean up
--------

Cleanup Kolla Docker containers and Docker volumes.

    ./kolla-ansible-aio kolla-ansible-cleanup

Cleanup hypervisor and remove virtual nodes.

    ./kolla-ansible-aio remove-virtual-nodes --yes-i-really-really-mean-it
