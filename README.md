Kolla-ansible-aio
=================

Multi-node deployment of Openstack Kolla-ansible using Libvirt and Ansible.

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

-   Multi-node (1 controller and 1 compute)
-   Multi OS (CentOS and Ubuntu compliancy)
-   Heavily automated using Ansible
-   Quick deployment: using PIP cache proxy (Devpi)
-   Quick deployment: using APT cache proxy (apt-cacher-ng) on Ubuntu

Quickstart guide
----------------

Install dependencies
--------------------

Make sure the PIP package manager is installed and upgraded to the latest version:

>    #CentOS
>    yum install epel-release
>    yum install python-pip
>    pip install -U pip
>
>    #Ubuntu
>    apt-get update
>    apt-get install python-pip
>    pip install -U pip

Install dependencies needed to build the code with PIP package manager:

>    #CentOS
>    yum install python-devel libffi-devel gcc openssl-devel libselinux-python
>
>    #Ubuntu
>    apt-get install python-dev libffi-dev gcc libssl-dev python-selinux

Install Ansible (> 2.3) using PIP:

>    #CentOS & Ubuntu
>    pip install -U ansible

Deployment
----------

Bootstrap hypervisor, Docker registry, proxies (PIP and APT), and create
virtual nodes.

    kolla-ansible-aio nodes-bootstrap

Bootstrap all virtual nodes (install packages, configure Docker,
configure SSH...).

    kolla-ansible-aio kolla-bootstrap

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
