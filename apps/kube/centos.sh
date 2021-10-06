#!/bin/bash

#set -x
set -e

echo centos > ~/.cluster-ansible-aio-env

OS='centos'

############ DO NOT MOVE ###############
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_params.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh
############ DO NOT MOVE ###############

KUBE_NIC_NAME="eth1"

# VM
####
if [ "$CREATE_INSTANCE" == true ]; then
    cd ${CAIO_DIR}
    ${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -s preflight -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix="" -e net_second_octet=${net_addr[${OS}]} -e vbmc=False -v
    if [ $? -eq 0 ]
    then
        echo "Intances successfully created"
    else
        echo "Intances creation failed" >&2
        exit 1
    fi
    snap_os ${OS}
fi


# # # NODE_PREFIX=${OS} ./virtual-manage --shutdown ${OS}
# # # NODE_PREFIX=${OS} ./virtual-manage --start ${OS}

# # # sleep 30


# # INVENTORY

generateInventory

# sed -i "s/centosworker4 internal_address=11.101.150.24 kube_hostname=centosworker4/centosworker4 internal_address=11.101.250.4 kube_hostname=centosworker4/" ~/work/Thales/kast_env/hosts
# sed -i  '/centosworker3 internal_address=11.101.150.23 kube_hostname=centosworker3/d' ~/work/Thales/kast_env/hosts


install_kube ${OS}
snap_kube ${OS}

install_kube_apps ${OS}
snap_kube_apps ${OS}

install_kube_apps_data ${OS}
