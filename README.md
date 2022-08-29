# Cluster-ansible-aio (all-in-one)

## Overview

Cluster-ansible-aio is a Vagrant like program for building and managing virtual machine environments in a single workflow.
Virtual machines are provisioned on top of Libvirt, or LXD (still beta) using heavily Ansible.
Cluster-ansible-aio is designed for everyone as the easiest and fastest way to create a virtualized environment!

![cluster-ansible-aio](https://user-images.githubusercontent.com/9655027/31175714-6e453b1e-a910-11e7-8a60-f7c6d2114b1a.png)

Cluster-ansible-aio is an open source tool for automating deployment of cluster apps on a single machine using Libvirt.

-   Source: <https://github.com/blallau/cluster-ansible-aio>

## Features

-   Libvirt(KVM) or LXD support(beta)
-   Multi Host OS (CentOS, Ubuntu)
-   Multi guest OS (CentOS, Ubuntu, Debian, Flatcar, Fedora CoreOS)
-   Multi network types using DHCP or static IPs
-   Multi block storage (using Logical Volume or QCOW2 files)
-   Heavily automated using Cloudinit for standard OS (or Ignition for immutable OS)
-   Heavily automated using Ansible
-   IPMI support using VirtualBMC

## Quickstart guide

### Install dependencies

Make sure the PIP package manager is installed and upgraded to the latest version:

```
#CentOS
sudo yum install epel-release
sudo yum install snapd python3-pip
sudo pip3 install -U pip

#Ubuntu or Debian
sudo apt-get update
sudo apt-get install snapd python3-pip
sudo pip3 install -U pip
```

Install Ansible (>= 2.9.13):

```
#CentOS & Ubuntu & Debian
sudo pip3 install -U ansible==2.9.13
```

#### Using virtual machines

##### Deployment

1. Clone cluster-ansible-aio.

Command:

    git clone https://github.com/blallau/cluster-ansible-aio
    cd cluster-ansible-aio

2. Put qcow2 guest OS images defined in roles/virtual_nodes/defaults/main.yml in "tmp_dir" (default: "${HOME}/tmp")

3. Describe the type of machine required and how to configure and provision these machines with variables from **group_vars/all.yml**

4. Bootstrap hypervisor, and create virtual nodes.

    ./cluster-ansible-aio create-virtual-nodes

Any of the default role variables can be easily overridden with variables from **group_vars/all.yml**
and **roles/virtual_nodes/vars/main.yml**.

##### Clean-up

1. Clean-up hypervisor and remove virtual nodes.

    ./cluster-ansible-aio remove-virtual-nodes --yes-i-really-really-mean-it

#### Using containers

##### Deployment

1. Clone cluster-ansible-aio.

Command:

    git clone https://github.com/blallau/cluster-ansible-aio
    cd cluster-ansible-aio

2. Bootstrap hypervisor and create container nodes.

    ./cluster-ansible-aio create-container-nodes

Any of the default role variables can be easily overridden with variables from **group_vars/all.yml**
and **roles/container_nodes/vars/main.yml**.

##### Clean-up

1. Clean-up hypervisor and remove container nodes.

    ./cluster-ansible-aio remove-container-nodes

## Troubleshooting guide

* deployment fails on "virtual_nodes : Get IP address of VM":
=> maybe network interfaces naming in VM is in conflict with cloudinit config.
