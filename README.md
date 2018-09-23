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

Deployment
----------

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

4. Build Kolla Docker images.

Command:

    ./kolla-ansible-aio kolla-build [-e install_type=binary] [-e kolla_build_profile=default]

5. Deploy multi-node Openstack using Kolla-ansible.

Command:

    ./kolla-ansible-aio kolla-ansible-deploy

Clean up
--------

Cleanup Kolla Docker containers and Docker volumes.

    ./kolla-ansible-aio kolla-ansible-cleanup

Cleanup hypervisor and remove virtual nodes.

    ./kolla-ansible-aio remove-virtual-nodes --yes-i-really-really-mean-it
