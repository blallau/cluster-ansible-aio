Bug Fix
-------
- Fix DNS issue when using Docker DNS server instead of Libvirt dnsmasq
- In case of many interfaces add check to have ext interface in 1 position

Features
--------
- Use block in some places to avoid 'when', 'sudo' statements repetition
  https://www.jeffgeerling.com/blog/new-features-ansible-20-blocks
