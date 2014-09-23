#!/bin/sh

# Extract required information from job ClassAd
while read line; do
   name="${line%% =*}"
   value="${line#*= }"
   case $name in
      ClusterId)
         cluster_id=$value
         ;;
      ProcId)
         proc_id=$value
         ;;
   esac
done

# Remove NFS exports
vacdir_out="/var/lib/vac/machines/$cluster_id/$proc_id/shared/machineoutputs"
vacdir_mf="/var/lib/vac/machines/$cluster_id/$proc_id/machinefeatures"
vacdir_job="/var/lib/vac/machines/$cluster_id/$proc_id/jobfeatures"
sudo /usr/sbin/exportfs -u 192.168.122.*:$vacdir_out
sudo /usr/sbin/exportfs -u 192.168.122.*:$vacdir_mf
sudo /usr/sbin/exportfs -u 192.168.122.*:$vacdir_job

# Add information from the shutdown message to the job ClassAd
message_file="/var/lib/vac/machines/$cluster_id/$proc_id/shared/machineoutputs/shutdown_message"
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
