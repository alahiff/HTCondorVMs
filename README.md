HTCondorVMs
===========

Adds the ability to a HTCondor pool for VMs to appear by "spontaneous production in the vacuum". Based on the ideas in http://www.gridpp.ac.uk/vac/.

## Worker node setup
* Enable virtualization in the BIOS
* Install libvirt, qemu-kvm, qemu-img, qemu-kvm-tools and any dependencies
* Make sure the libvirtd service is running
* Add the appropriate HTCondor VM configuration; see https://github.com/alahiff/HTCondorVMs/blob/master/vm-universe.config
* Restart HTCondor and check that "VMType('kvm') is supported" appears in /var/log/condor/StartLog
