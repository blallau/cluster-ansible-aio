#!/bin/bash
set -x
#set -e

echo debian > ~/.cluster-ansible-aio-env

OS='debian'

############ DO NOT MOVE ###############
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_params.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh
############ DO NOT MOVE ###############

KUBE_NIC_NAME="enp2s0"

# VM
####
if [ "$CREATE_INSTANCE" == true ]; then
    cd ${CAIO_DIR}
    ${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -s preflight -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix="" -e net_second_octet=${net_addr[${OS}]} -v
    if [ $? -eq 0 ]
    then
        echo "Intances successfully created"
    else
        echo "Intances creation failed" >&2
        exit 1
    fi
    snap_os ${OS}
fi

# INVENTORY
###########
generateInventory


# sleep 10
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
# sleep 60
# exit 1

install_kube ${OS}
snap_kube ${OS}

install_kube_apps ${OS}
snap_kube_apps ${OS}

install_kube_apps_data ${OS}
