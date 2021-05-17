Bug Fix/Todo list
-----------------
- Fix DNS issue when using Docker DNS server instead of Libvirt dnsmasq
- In case of many interfaces add check to have ext interface in 1 position
- manage node-prefix in SSH keys and libvirt network, ... in order to not remove env from previous deployment
- remove shutdown before snapshot
- remove name or bridge in net_interfaces (redondant info)
- automaticaly retrieve last iso images (debian,centos), to avoid too long package update
- fix gracefully-shutdown
- manage QCOW2 with baseimagefile
- add task to wait for Flatcar VMs ready
- manage remote libvirtd
- fix bug when different deployments use the same networks
  => IPs/macs association cannot be set in the previous DHCP config
  => IPs are random => hence deployment fails [Waiting on IPs]

Take a look at:
https://github.com/csmart/ansible-role-virt-infra
https://github.com/goffinet/ansible-role-virt-infra
