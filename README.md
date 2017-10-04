Kolla-ansible-aio
=================

Multi-node deployment of Kolla-ansible using Libvirt and Ansible.

![kolla-ansible-aio][kolla-ansible-aio.png]

Kolla-ansible-aio is an open source tool for automating deployment of
Kolla-ansible in multi-node scenario, on a single machine.
Kolla-ansible-aio is composed of Ansible playbooks, and makes heavy use
of Libvirt, OpenStack Kolla and Kolla-ansible project.

Kolla-ansible-aio aims to test, use and develop on Kolla and
Kolla-ansible projects.

-   Source: <https://github.com/blallau/kolla-ansible-aio>

Features
--------

-   Multi-node (1 controller and 1 compute)
-   Multi OS (CentOS and Ubuntu compliancy)
-   Heavily automated using Ansible
-   Quick deployment: using PIP cache proxy (Devpi)
-   Quick deployment: using APT cache proxy (apt-cacher-ng) on Ubuntu

Quickstart guide
----------------

Deployment
----------

Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

    kolla-ansible-aio nodes-boostrap

Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

    kolla-ansible-aio kolla-boostrap

Build Kolla Docker images.

    kolla-ansible-aio kolla-build

Deploy multi-node Openstack using Kolla-ansible.

    kolla-ansible-aio kolla-ansible-deploy

Clean up
--------

Cleanup Kolla Docker containers and Docker volumes

    kolla-ansible-aio kolla-ansible-cleanup

Cleanup hypervisor and remove virtual nodes.

    kolla-ansible-aio nodes-cleanup --yes-i-really-really-mean-it
