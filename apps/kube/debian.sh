#!/bin/bash
set -x
set -e

echo debian > ~/.cluster-ansible-aio-env

. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_common.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh

OFFLINE=true
WORKER_NB=1
OS='debian'
LB_NB=2
KUBE_HA=true

# INVENTORY
###########
generateInventory

# VM
####
cd ${CAIO_DIR}
${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -s preflight -e lb_nb=${LB_NB} -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix=${OS::3} -e net_second_octet=${net_addr[${OS}]} -v

# sleep 10
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
# sleep 60
# exit 1

# LB
######

if [ "$LB_NB" -gt "0" ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -u debian playbooks/lb.yml
fi

# KUBE
######
retrieveArtifacts

if [ "${MULTUS_ENABLED}" == true ] && [ "${MULTUS_TECH}" = "bridge" ]; then
    cd ${CAIO_DIR}
    ansible-playbook -i ${KAST_INV} -e os_default_user=${OS} apps/kube/bridge_net.yml
    # # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
    # sleep 30
fi

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} -u debian playbooks/containerd_install.yml

# sleep 60
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-containerd
# sleep 60
# exit 1

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} -u debian playbooks/kube.yml

cd ${CAIO_DIR}
ansible-playbook -i ${KAST_INV} -e os_default_user=${OS} apps/kube/kube-cli.yml

# # sleep 60
# # cd ${CAIO_DIR}
# # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-kube
# # exit 0

if [ "$MINIO_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -u debian playbooks/s3_storage.yml
    # wget https://dl.min.io/client/mc/release/linux-amd64/mc
    # chmod +x mc
fi

if [ "$REGISTRY_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -u debian playbooks/registry.yml
fi

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} -u debian playbooks/ingress.yml

if [ "$DASHBOARD_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -u debian playbooks/dashboard.yml
fi

# deploy calicoctl
calicoClient

# sleep 120
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-${CNI_PLUGIN}
# sleep 10
# exit 1

# IAM
if [ "$IAM_ENABLED" = true ]; then
    # Install postgres
    cd ${KAST_DIR}
    ansible -i ${KAST_INV} postgresql -b -m file -a "path=/data/postgresql state=directory"
    ansible-playbook -i ${KAST_INV} -u debian playbooks/sql_db.yml

    # Install Keycloak
    cd ${KAST_DIR}/install/kast-initial
    ansible-playbook -i ${KAST_INV} -u debian tools/playbooks/iam_preinstall.yml

    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -e keycloak_debug_enabled=true -u debian playbooks/iam.yml

    cd ${KAST_DIR}/install/kast-initial
    ansible-playbook -K -i ${KAST_INV} tools/playbooks/iam_postinstall.yml
fi

# longhorn
Longhorn

if [ "$OPENEBS_ENABLED" = true ]; then
    kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
fi

# Multus
Multus

if [ "$ROOK_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} -u debian playbooks/rook_ceph.yml
fi

# cd ${CAIO_DIR}
# 360 KO
# 420 ??
# sleep 600
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-${CNI_PLUGIN}-rook-ceph
