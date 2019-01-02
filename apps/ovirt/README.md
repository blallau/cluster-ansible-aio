oVirt Deployment
================

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

    ./cluster-ansible-aio nodes-bootstrap -e nested_virt_enabled=true

4. Deploy oVirt.

Command:

    cd apps/ovirt
    ./cluster-ansible-aio ovirt-deploy

5. Populate oVirt.

Command:

    ./cluster-ansible-aio ovirt-populate
