#!/bin/bash
set -x
set -e

. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_common.sh
. ${HOME}/work/GIT/cluster-ansible-aio/apps/kube/kube_lib.sh

# INVENTORY
###########
generateInventory

# VM
####
cd ${CAIO_DIR}
${CAIO_DIR}/cluster-ansible-aio create-virtual-nodes -e worker_nb=${WORKER_NB} -e docker_enabled=false -e guest_os_distro=${OS} -e node_prefix=${OS} -e net_prefix=${OS::3} -e net_second_octet=${net_addr[${OS}]} -v

sleep 10
cd ${CAIO_DIR}
NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
sleep 60
exit 1

if [ "${MULTUS_ENABLED}" == true ] && [ "${MULTUS_TECH}" = "bridge" ]; then
    cd ${CAIO_DIR}
    ansible-playbook -i ${KAST_INV} -e os_default_user=${OS} apps/kube/bridge_net.yml
    # # NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}
    # sleep 30
fi

# KUBE
######

retrieveArtifacts

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} playbooks/containerd_install.yml

# sleep 60
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-containerd
# sleep 60
# exit 1

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} playbooks/kube.yml

cd ${CAIO_DIR}
ansible-playbook -i ${KAST_INV} -e os_default_user=${OS} apps/kube/kube-cli.yml

# sleep 60
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-kube


if [ "$MINIO_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} playbooks/s3_storage.yml
    # wget https://dl.min.io/client/mc/release/linux-amd64/mc
    # chmod +x mc
fi

if [ "$REGISTRY_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} playbooks/registry.yml
fi

cd ${KAST_DIR}
ansible-playbook -i ${KAST_INV} playbooks/ingress.yml

if [ "$DASHBOARD_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} playbooks/dashboard.yml
fi

# sleep 10
# cd ${CAIO_DIR}
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-${CNI_PLUGIN}
# sleep 30

# deploy calicoctl
calicoClient

# longhorn
Longhorn

if [ "$OPENEBS_ENABLED" = true ]; then
    kubectl apply -f https://openebs.github.io/charts/openebs-operator.yaml
fi

# Multus
Multus

if [ "$ROOK_ENABLED" = true ]; then
    cd ${KAST_DIR}
    ansible-playbook -i ${KAST_INV} playbooks/rook_ceph.yml
fi

# cd ${CAIO_DIR}
# 360 KO
# 420 ??
# sleep 600
# NODE_PREFIX=${OS} ./virtual-manage --snap-create ${OS}-${CNI_PLUGIN}-rook-ceph
