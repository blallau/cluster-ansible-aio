OpenShift Deployment
====================

1. Clone cluster-ansible-aio.

Command:

    git clone https://github.com/blallau/cluster-ansible-aio
    cd cluster-ansible-aio/

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

Command:

    ./cluster-ansible-aio create-virtual-nodes -e vm_os_distro=centos

3. Bootstrap OpenShift.

Command:

    ansible-playbook -i ../OPENSHIFT/openshift-ansible/inventory/hosts prepare.yml
    ansible-playbook -i ../OPENSHIFT/openshift-ansible/inventory/deploy_cluster.yml
