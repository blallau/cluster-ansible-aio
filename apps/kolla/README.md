Kolla Deployment
================

1. Clone cluster-ansible-aio.

Command:

    git clone https://github.com/blallau/cluster-ansible-aio
    cd cluster-ansible-aio

2. Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

By default, virtual nodes OS will be same as hypervisor OS.

    ./cluster-ansible-aio create-virtual-nodes

Any of the default role variables can be easily overridden with variables from **group_vars/all.yml**

3. Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

Command:

    ./cluster-ansible-aio nodes-bootstrap

4. Bootstrap Kolla nodes.

Command:

    cd apps/kolla
    ./cluster-ansible-aio kolla-bootstrap

5. Build Kolla Docker images.

Command:

    ./cluster-ansible-aio kolla-build [-e install_type=binary] [-e kolla_build_profile=default]

6. Deploy multi-node Openstack using Kolla-ansible.

Command:

    ./cluster-ansible-aio kolla-ansible-deploy

Clean-up
--------

Clean-up Kolla Docker containers and Docker volumes.

    ./cluster-ansible-aio kolla-ansible-cleanup

Clean-up hypervisor and remove virtual nodes.

    ./cluster-ansible-aio remove-virtual-nodes --yes-i-really-really-mean-it
