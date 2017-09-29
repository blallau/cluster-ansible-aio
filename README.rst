=================
Kolla-ansible-aio
=================

Multinode deployment of Kolla-ansible using Libvirt and Ansible.

Kolla-ansible-aio is an open source tool for automating deployment
of Kolla-ansible in multi nodes scenario, on a single machine using Libvirt.
Kolla-ansible-aio is composed of Ansible playbooks, and makes heavy use
of the OpenStack Kolla and Kolla-ansible project.
Kolla-ansible-aio aims to test, use and develop on Kolla and Kolla-ansible projects.

* Source: https://github.com/blallau/kolla-ansible-aio

Features
--------

- Multi nodes (1 controller and 1 compute)
- Multi OS (CentOS and Ubuntu compliancy)
- Heavily automated using Ansible
- Quick deployment:
- using PIP cache proxy (Devpi)
- APT cache proxy (apt-cacher-ng) for Ubuntu

Quickstart guide
----------------

Deployment
----------

Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create virtual nodes.

::

    kolla-ansible-aio nodes-boostrap

Bootstrap all virtual nodes.

::

    kolla-ansible-aio kolla-ansible-boostrap

Build Kolla images.

::

    kolla-ansible-aio kolla-build

Deploy Openstack on nodes using Kolla-ansible.

::

    kolla-ansible-aio kolla-ansible-deploy

Clean up
--------

Cleanup hypervisor and remove virtual nodes.

::

    kolla-ansible-aio nodes-cleanup

Cleanup Kolla containers and volumes

::

    kolla-ansible-aio kolla-ansible-cleanup
