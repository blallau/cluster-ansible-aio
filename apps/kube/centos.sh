#!/bin/bash

set -x
set -e

echo centos > ${HOME}/.cluster-ansible-aio-env

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
    ${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -s preflight -e lb_nb=${LB_NB} -e master_nb=${MASTER_NB} -e worker_nb=${WORKER_NB} -e docker_enabled=false -e node_prefix=${OS} -e net_prefix="" -e vbmc=False -v
    if [ $? -eq 0 ]
    then
        echo "Intances successfully created"
    else
        echo "Intances creation failed" >&2
        exit 1
    fi
fi
snap_os ${OS}

# # INVENTORY
###########
generateInventory

if [ "$PROMPT_USER" == true ]; then
    read -p "Press enter to continue"
fi

# install_kube ${OS}
# snap_kube ${OS}

# if [ "$PROMPT_USER" == true ]; then
#     read -p "Press enter to continue"
# fi

# install_kube_apps ${OS}
# snap_kube_apps ${OS}

# if [ "$PROMPT_USER" == true ]; then
#     read -p "Press enter to continue"
# fi

install_kube_apps_data ${OS}
install_netpols ${OS}
