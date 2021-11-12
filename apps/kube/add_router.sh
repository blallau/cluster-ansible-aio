#!/bin/bash

declare -A vm_num
vm_num['centosworker1']=21
vm_num['centosworker2']=22
vm_num['centosworker3']=23
vm_num['centosworker4']=24

OVER_IP_PREFIX="11.101.150"
OVER2_IP_PREFIX="11.101.250"

MAC_PREFIX="52:54:00:32"

MASTER1_DOM_NAME="centosmaster1"
WORKER1_DOM_NAME="centosworker1"
WORKER2_DOM_NAME="centosworker2"
ROUTER_DOM_NAME="centosworker3"
WORKER4_DOM_NAME="centosworker4"

INITIAL_OVERLAY_NET="over-br"
ADDED_OVERLAY_NET="over2-br"

attach() {
    domain_name=$1
    net_name=$2
    mac_idx=$3
    virsh attach-interface --domain ${domain_name} --type bridge \
          --source ${net_name} --model virtio \
          --mac "${MAC_PREFIX}:${vm_num[$domain_name]}:0${mac_idx}" --config --live
}

detach() {
    domain_name=$1
    net_name=$2
    mac_idx=$3
    virsh detach-interface --domain ${domain_name} --type bridge \
          --mac "${MAC_PREFIX}:${vm_num[$domain_name]}:0${mac_idx}" --config --live
}

net_update() {
    net_name=$1
    action=$2
    ip=$3
    mac=$4
    virsh net-update ${net_name} ${action} ip-dhcp-host \
          "<host mac='${MAC_PREFIX}:${mac}' ip='${ip}' />" \
           --config --live
}

virsh net-undefine ${ADDED_OVERLAY_NET}
virsh net-destroy ${ADDED_OVERLAY_NET}

# create over2
cat << EOF > ${ADDED_OVERLAY_NET}.xml
<network>
  <name>${ADDED_OVERLAY_NET}</name>
  <bridge name='${ADDED_OVERLAY_NET}' stp='on' delay='0'/>
  <mtu size='9000'/>
  <ip address='${OVER2_IP_PREFIX}.1' netmask='255.255.255.0'><dhcp/></ip>
</network>
EOF

virsh net-define --file ${ADDED_OVERLAY_NET}.xml
virsh net-start ${ADDED_OVERLAY_NET}
virsh net-autostart ${ADDED_OVERLAY_NET}

exit
#
#       w1            w2            w3            W4
#                      over-br
# 11.101.150.21 11.101.150.22 11.101.150.23 11.101.150.24
#
#       w1            w2            w3            W4
#                   over-br ----- router ----- over-br2
# 11.101.150.21 11.101.150.22 11.101.150.1
#                             11.101.250.1 11.101.250.24

# detach over from remote VM
detach $WORKER4_DOM_NAME $INITIAL_OVERLAY_NET "2"
# attach over2 to remote VM
attach $WORKER4_DOM_NAME $ADDED_OVERLAY_NET "2"
# attach over2 to router
attach $ROUTER_DOM_NAME $ADDED_OVERLAY_NET "3"

# update worker3 IP to Gateway IP 6
net_update $INITIAL_OVERLAY_NET modify "${OVER_IP_PREFIX}.6" "23:02"
# remove worker4 IP from over
net_update $INITIAL_OVERLAY_NET delete "${OVER_IP_PREFIX}.24" "24:02"
# add worker3 IP to over2 (as gateway .1)
net_update $ADDED_OVERLAY_NET add "${OVER2_IP_PREFIX}.6" "23:03"
# add worker4 IP to over2
net_update $ADDED_OVERLAY_NET add "${OVER2_IP_PREFIX}.4" "24:02"

# activate routing mode
ssh $ROUTER_DOM_NAME "echo net.ipv4.ip_forward = 1 | sudo tee /etc/sysctl.conf"
ssh $ROUTER_DOM_NAME "sudo sysctl -w net.ipv4.ip_forward=1"x

ssh $WORKER4_DOM_NAME "echo SUBSYSTEM==\"net\", ACTION==\"add\", DRIVERS==\"?*\", ATTR{address}==\"${MAC_PREFIX}:24:02\", ATTR{type}==\"1\", KERNEL==\"eth*\", NAME=\"eth1\" | sudo tee /etc/udev/rules.d/70-persistent-net.rules"
ssh $WORKER4_DOM_NAME "echo -en 'DEVICE=eth1\nBOOTPROTO=none\nONBOOT=yes\nPREFIX=24\nIPADDR=${OVER2_IP_PREFIX}.4\n' | sudo tee /etc/sysconfig/network-scripts/ifcfg-eth1"
ssh $WORKER4_DOM_NAME "echo ${OVER_IP_PREFIX}.0/24 via ${OVER2_IP_PREFIX}.6 dev eth1 | sudo tee /etc/sysconfig/network-scripts/route-eth1"

ssh $MASTER1_DOM_NAME "echo ${OVER2_IP_PREFIX}.0/24 via ${OVER_IP_PREFIX}.6 dev eth1 | sudo tee /etc/sysconfig/network-scripts/route-eth1"

ssh $WORKER1_DOM_NAME "echo ${OVER2_IP_PREFIX}.0/24 via ${OVER_IP_PREFIX}.6 dev eth1 | sudo tee /etc/sysconfig/network-scripts/route-eth1"
ssh $WORKER2_DOM_NAME "echo ${OVER2_IP_PREFIX}.0/24 via ${OVER_IP_PREFIX}.6 dev eth1 | sudo tee /etc/sysconfig/network-scripts/route-eth1"

# reboot affected nodes
# To manage reload net.ipv4.ip_forward = 1
ssh $ROUTER_DOM_NAME "sudo reboot"
# To manage udev rule
ssh $WORKER4_DOM_NAME "sudo reboot"

ssh $MASTER1_DOM_NAME "sudo ifdown eth1; sudo ifup eth1"

ssh $WORKER1_DOM_NAME "sudo ifdown eth1; sudo ifup eth1"
ssh $WORKER2_DOM_NAME "sudo ifdown eth1; sudo ifup eth1"
