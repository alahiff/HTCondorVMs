#!/bin/sh

# Extract required information from job ClassAd
while read line; do
   name="${line%% =*}"
   value="${line#*= }"
   case $name in
      Iwd)
         path="${value//\"}"
         ;;
      PublicKey)
         public_key="${value//\"}"
         ;;
      VMPARAM_vm_Disk)
         vm_disk="${value//\"}"
         ;;
      UserData)
         user_data="${value//\"}"
         ;;
      VacSpace)
         vac_space="${value//\"}"
         ;;
      ClusterId)
         cluster_id=$value
         ;;
      ProcId)
         proc_id=$value
         ;;
   esac
done

# Create context.sh
cat <<EOF >context.sh
# Context variables used by amiconfig
ROOT_PUBKEY=root.pub
ONE_CONTEXT_PATH="/var/lib/amiconfig"
EOF

# Setup NFS exports
vacdir_out="$path/machineoutputs"
vacdir_mf="$path/machinefeatures"
vacdir_job="$path/jobfeatures"
mkdir -p $vacdir_out
mkdir -p $vacdir_mf
mkdir -p $vacdir_job
sudo /usr/sbin/exportfs -o no_root_squash,rw 192.168.122.*:$vacdir_out
sudo /usr/sbin/exportfs -o no_root_squash,rw 192.168.122.*:$vacdir_mf
sudo /usr/sbin/exportfs -o no_root_squash,rw 192.168.122.*:$vacdir_job

# Required jobfeatures & machinefeatures
if [ -n "$vac_space" ]; then
   echo $vac_space > $vacdir_mf/vac_space
fi
echo "$cluster_id.$proc_id" > $vacdir_mf/vac_uuid
echo "raltest" > $vacdir_mf/vac_vmtype
echo "259200" > $vacdir_job/cpu_limit_secs

# Condor will try to transfer these files back to the submit node - if
# they're not there for some reason this will cause the job to go into
# the held state
touch $vacdir_out/vm-bootstrap.log
touch $vacdir_out/vm-pilot.log

# Determine the name of the slot & hostname
machine_name=`grep Name .machine.ad | grep slot | awk '{print $3}'`
machine_name="${machine_name//\"}"
slot_name=(${machine_name//@/ })
host_name=${machine_name//@/-}
host_name=${host_name//_/-}

# Create prolog.sh
cat <<EOF1 >prolog.sh
#!/bin/sh
if [ "\$1" = "start" ] ; then
  hostname $host_name
  mkdir -p /etc/machinefeatures /etc/jobfeatures /etc/machineoutputs /etc/vmtypefiles
  cat <<EOF >/etc/cernvm/cernvm.d/S50vac.sh
#!/bin/sh
mount -o rw,nfsvers=3 $HOSTNAME:$vacdir_out /etc/machineoutputs
mount -o rw,nfsvers=3 $HOSTNAME:$vacdir_mf /etc/machinefeatures
mount -o rw,nfsvers=3 $HOSTNAME:$vacdir_job /etc/jobfeatures
EOF
  chmod ugo+x /etc/cernvm/cernvm.d/S50vac.sh
fi
# end of vac prolog.sh
EOF1

# Create user data & add to context.sh
user_data_base64=`base64 -w 0 $user_data`
echo "EC2_USER_DATA=$user_data_base64" >> context.sh

# Create a temporary directory containing contextualization files
tmpdir=`mktemp -dp $path`
cp $public_key $tmpdir/.
cp context.sh $tmpdir/.
cp prolog.sh $tmpdir/.

# Create contextualization iso
genisoimage -quiet -o context.iso $tmpdir
rm -rf $tmpdir

# Create CVMFS cache
truncate -s 20G cernvm-hd.img

# Create scratch disk
dd of=disk.img bs=1 seek=30G count=0

# Keep a copy of .chirp_config for use in the exit hook script
chirpfile="/tmp/chirp_"$cluster_id"_"$proc_id
cp .chirp_config $chirpfile

# Update vm_disk to include contextualization iso (assume hdd) & CVMFS cache (assume vda)
vm_disk_new="\""$vm_disk","$path"/context.iso:hdd:r:raw,"$path"/cernvm-hd.img:vda:w,"$path"/disk.img:vdb:w:raw\""
echo "VMPARAM_vm_Disk = $vm_disk_new"

exit 0

