HTCondorVMs
===========

Adds the ability to a HTCondor pool for VMs to appear by "spontaneous production in the vacuum". Based on the ideas in http://www.gridpp.ac.uk/vac/.

### Worker node setup
* Enable virtualization in the BIOS
* Install the libvirt, qemu-kvm, qemu-img, and qemu-kvm-tools rpms plus any dependencies
* Make sure the nfs and libvirtd services is running
* Enable IP forwarding, i.e. /proc/sys/net/ipv4/ip_forward should be 1
* Add the appropriate HTCondor VM configuration; see https://github.com/alahiff/HTCondorVMs/blob/master/vm-universe.config
* Add the files libvirt_cernvm_script.awk, vac_prepare_hook.sh and vac_exit_hook.sh to /usr/local/libexec on the worker node
* Restart HTCondor on the worker node
* Modify sudoers so that the user running the VMs is able to run /usr/sbin/exportfs as root
* 
### Worker node checks
* Run "egrep -c '(svm|vmx)' /proc/cpuinfo" to check if your CPUs support virtualization. A result of zero indicates that they do not.
* Check that "VMType('kvm') is supported" appears in /var/log/condor/StartLog
* Run "condor_status -vm" to check the your worker nodes with virtualization appear

### Prepare user data
* For ATLAS, follow http://svnweb.cern.ch/world/wsvn/vacproject/atlas/README
* For LHCb, follow https://twiki.cern.ch/twiki/bin/view/LHCb/VacConfiguration
* For GridPP, follow https://www.gridpp.ac.uk/wiki/Vac_configuration_for_GridPP_DIRAC
* 
### Running the scheduler universe job
