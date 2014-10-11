HTCondorVMs
===========

Adds the ability to a HTCondor pool for VMs to appear by "spontaneous production in the vacuum". Based on the ideas in http://www.gridpp.ac.uk/vac/.

### Worker node setup
* Enable virtualization in the BIOS
* Install the libvirt, qemu-kvm, qemu-img, and qemu-kvm-tools rpms plus any dependencies
* Make sure the libvirtd service is running
* Add the appropriate HTCondor VM configuration; see https://github.com/alahiff/HTCondorVMs/blob/master/vm-universe.config
* Add the files libvirt_cernvm_script.awk, vac_prepare_hook.sh and vac_exit_hook.sh to /usr/local/libexec on the worker node
* Restart HTCondor and check that "VMType('kvm') is supported" appears in /var/log/condor/StartLog
