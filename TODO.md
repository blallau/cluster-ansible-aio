Bug Fix/Todo list
-----------------
- add label to loop in order to resume loop iteration display
- check network use in nodes exists in networks
- 'ansible_user' undefined
=> libvirt_inventory.py can't retrieve dhcp lease (sudo dhclient eth0)_
- In case of many interfaces add check to get external interface first
- manage node-prefix in SSH keys and libvirt network, ... in order to not remove env from previous deployment
- fix gracefully-shutdown
- add task to wait for Flatcar VMs ready
- fix bug when different deployments use the same networks
  => IPs/macs association cannot be set in the previous DHCP config
  => IPs are random => hence deployment fails [Waiting on IPs]
- fix idempotency when playbook is running twice

- [manage QCOW2 with a baseimagefile]
- [Fix DNS issue when using Docker DNS server instead of Libvirt dnsmasq]
- [automaticaly retrieve last iso images (debian,centos), to avoid too long package update]
- [manage remote libvirtd]
- [remove shutdown before snapshot]
=> use qemu-guest-agent (fsfreeze before snapshot)
=> NO: external snapshot doesn't manage Guest VM


check https://github.com/hicknhack-software/ansible-libvirt

- fix SNAP_NAME and SNAPSHOT_NAME redondancy

LXD

https://github.com/hispanico/ansible-lxd
https://github.com/plumelo/ansible-role-lxd/blob/master/tasks/containers.yml
https://github.com/Nani-o/ansible-inventory-lxd
https://github.com/Nani-o/ansible-role-lxd

LXD - storage
https://discourse.world/h/2020/04/09/Basic-LXD-Features-Linux-Container-Systems
https://doc.zordhak.fr/d/LXD/LXD_-_Installation_et_configuration.html
https://linuxcontainers.org/lxd/docs/master/storage/#lvm
https://linuxcontainers.org/lxd/docs/master/storage/#the-following-commands-can-be-used-to-create-lvm-storage-pools

LXD - network
https://github.com/Nani-o/ansible-role-lxd

OpenStack
https://github.com/jthadden/OpenStack_Summit_2018_Vancouver/
https://docs.openstack.org/charm-guide/queens/openstack-on-lxd.html

https://www.digitalocean.com/community/tutorials/how-to-set-up-and-use-lxd-on-ubuntu-18-04
https://blog.simos.info/how-to-initialize-lxd-again/

Snapshot
https://fedoraproject.org/wiki/Features/Virt_Live_Snapshots
https://wiki.libvirt.org/page/I_created_an_external_snapshot,_but_libvirt_will_not_let_me_delete_or_revert_to_it
