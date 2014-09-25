#!/bin/sh

# Extract required information from job ClassAd
while read line; do
   name="${line%% =*}"
   value="${line#*= }"
   case $name in
      Iwd)
         path="${value//\"}"
         ;;
      ClusterId)
         cluster_id=$value
         ;;
      ProcId)
         proc_id=$value
         ;;
   esac
done

# Remove NFS exports
vacdir_out="$path/machineoutputs"
vacdir_mf="$path/machinefeatures"
vacdir_job="$path/jobfeatures"
sudo /usr/sbin/exportfs -u 192.168.122.*:$vacdir_out
sudo /usr/sbin/exportfs -u 192.168.122.*:$vacdir_mf
sudo /usr/sbin/exportfs -u 192.168.122.*:$vacdir_job

# Add information from the shutdown message to the job ClassAd
message_file="$path/machineoutputs/shutdown_message"
chirpfile="/tmp/chirp_"$cluster_id"_"$proc_id
if [ -f $message_file ];
then
   message=`cat $message_file | sed -e 's/^\w*\ *//'`
   code=`cat $message_file | awk '{print $1}'`
   cp $chirpfile .chirp.config
   /usr/libexec/condor/condor_chirp set_job_attr ShutdownMessage "\"$message\""
   /usr/libexec/condor/condor_chirp set_job_attr ShutdownCode $code
fi
rm -f $chirpfile

# Clean-up images
rm -f disk.img
rm -f context.iso
rm -f cernvm-hd.img
