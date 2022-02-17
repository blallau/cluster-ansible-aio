Bug Fix/Todo list
-----------------
- check network use in nodes exists in networks
- 'ansible_user' undefined
=> libvirt_inventory.py can't retrieve dhcp lease (sudo dhclient eth0)_
- In case of many interfaces add check to get external interface first
- manage node-prefix in SSH keys and libvirt network, ... in order to not remove env from previous deployment
- remove shutdown before snapshot => use fsfreeze before snapshot ?
- fix gracefully-shutdown
- add task to wait for Flatcar VMs ready
- fix bug when different deployments use the same networks
  => IPs/macs association cannot be set in the previous DHCP config
  => IPs are random => hence deployment fails [Waiting on IPs]
- manage idempotency when playbook is running twice

- [manage QCOW2 with a baseimagefile]
- [Fix DNS issue when using Docker DNS server instead of Libvirt dnsmasq]
- [automaticaly retrieve last iso images (debian,centos), to avoid too long package update]
- [manage remote libvirtd]


check https://github.com/hicknhack-software/ansible-libvirt

- fix SNAP_NAME and SNAPSHOT_NAME redondancy
