HTCondorVMs
===========

Adds the ability to a HTCondor pool for VMs to appear by "spontaneous production in the vacuum". Based on the ideas in http://www.gridpp.ac.uk/vac/ but here the VMs are mananged by HTCondor. A permanently running scheduler universe job submits VM universe jobs as necessay. If there is an error or is no work available, 2 VMs are created every 30 minutes. If work is available, more VMs are created until work runs out or too many VMs stay in the idle state.

### Worker node setup
* Enable virtualization in the BIOS
* Install the libvirt, qemu-kvm, qemu-img, and qemu-kvm-tools rpms plus any dependencies
* Make sure the nfs and libvirtd services are running
* Enable IP forwarding, i.e. /proc/sys/net/ipv4/ip_forward should be 1
* Add the appropriate HTCondor VM configuration; see https://github.com/alahiff/HTCondorVMs/blob/master/vm-universe.config
* Add the files libvirt_cernvm_script.awk, vac_prepare_hook.sh and vac_exit_hook.sh to /usr/local/libexec on the worker node
* Restart HTCondor on the worker node
* Modify sudoers so that the user running the VMs is able to run /usr/sbin/exportfs as root

### Worker node checks
* Run "egrep -c '(svm|vmx)' /proc/cpuinfo" to check if your CPUs support virtualization. A result of zero indicates that they do not.
* Check that "VMType('kvm') is supported" appears in /var/log/condor/StartLog
* Run "condor_status -vm" to check the your worker nodes with virtualization appear

### Prepare user data
User data needs to be prepared in exactly the same way as done for Vac.
* For ATLAS, see http://svnweb.cern.ch/world/wsvn/vacproject/atlas/README
* For LHCb, see https://twiki.cern.ch/twiki/bin/view/LHCb/VacConfiguration
* For GridPP, see https://www.gridpp.ac.uk/wiki/Vac_configuration_for_GridPP_DIRAC

### Running the scheduler universe job
* Download the latest CernVM 3 iso from here http://cernvm.cern.ch/portal/downloads
* Edit the job description file for creating the VMs as appropriate. An example is https://github.com/alahiff/HTCondorVMs/blob/master/vm-atlas.sub 
