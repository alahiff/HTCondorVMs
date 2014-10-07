#!/usr/bin/python
# This is intended to be submitted to HTCondor as a scheduler universe job.
# Example job submission script:
#   universe = scheduler
#   cmd = condor-vac.py
#   arguments = vm-atlas05.sub VAC-ATLAS
#   hold_kill_sig = SIGUSR1
#   remove_kill_sig = SIGUSR2
#   log=/tmp/log.$(Cluster).$(Process)
#   output=/tmp/out.$(Cluster).$(Process)
#   error=/tmp/err.$(Cluster).$(Process)
#   on_exit_remove = ExitCode =!= UNDEFINED && ExitCode == 42
#   queue
 
import signal, time, sys
import classad
import htcondor
import classad
import subprocess
import socket

running = True
 
def rm_handler(signum, frame):
    global running
    # Someone ran condor_rm on me!
    running = False
 
def hold_handler(signum, frame):
    global running
    # Someone ran condor_hold on me!
    running = False
 
signal.signal(signal.SIGUSR1, hold_handler)
signal.signal(signal.SIGUSR2, rm_handler)

submitScript = sys.argv[1]
label = sys.argv[2]

# Configuration
# - how often to run
runEvery = 60
# - maximum number of idle VMs
maxIdleJobs = 10
# - maximum number of VMs to run after waiting
maxJobsAfterWaiting = 2
# - threshold (in s) for short jobs - VMs running less than this time are assumed
#   to not be real jobs
thresholdShortJobs = 1800
# - threshold (in s) for long jobs - VMs running more than this time are assumed
#   to be real jobs
thresholdGoodJobs = 1800
# - threshold for 
thresholdNumGoodJobs = 2
# - hostname of condor collector
collector = "condor01.gridpp.rl.ac.uk"
# - path where log files should be written
logPath = "/scratch/alahiff"

# Function for writing log messages
def log(message):
   now = time.strftime("%c")
   with open(logPath+"/vac-"+label+".log", "a") as f:
      f.write(time.strftime("%c ")+message+"\n")
 
# Main loop
while running:
   log("--- STARTING RUN ---")

   coll = htcondor.Collector(collector)
   schedd_ad = coll.locate(htcondor.DaemonTypes.Schedd, socket.gethostname())
   schedd = htcondor.Schedd(schedd_ad)

   # Check for recently completed jobs
   jobs = schedd.query('RequiresVac =?= True && Cmd == "'+label+'" && JobStatus == 4',["ClusterId", "ProcId", "CompletionDate", "RemoteWallClockTime", "ShutdownCode"])

   mostRecentWall = -1
   mostRecentShutdownCode = -1
   mostRecentJob = -1
   mostRecentClusterId = -1
   mostRecentProcId = -1

   for job in jobs:
      if job["CompletionDate"] > mostRecentJob:
         mostRecentWall = job["RemoteWallClockTime"]
         if "ShutdownCode" in job:
            mostRecentShutdownCode = job["ShutdownCode"]
         mostRecentJob = job["CompletionDate"]
         mostRecentClusterId = job["ClusterId"]
         mostRecentProcId = job["ProcId"]

   if mostRecentClusterId > 0:
      log("wall,code,time = "+str(mostRecentWall)+","+str(mostRecentShutdownCode)+","+str(mostRecentJob)+" for jobid "+str(mostRecentClusterId)+"."+str(mostRecentProcId))
   else:
      log("no recent completed jobs")

   if mostRecentWall > 0 and (mostRecentWall < thresholdShortJobs or mostRecentShutdownCode != 200):
      log("Waiting - no recent successful VMs")
   else:
      log("Preparing to submit VMs if necessary")

      # get number of idle jobs
      jobs = schedd.query('RequiresVac =?= True && Cmd == "'+label+'" && JobStatus == 1',["ClusterId", "ProcId"])
      numIdle = 0
      for job in jobs:
         numIdle = numIdle + 1

      numToSubmit = 1
      # get number of jobs probably running real work
      jobs = schedd.query('RequiresVac =?= True && Cmd == "'+label+'" && JobStatus == 2 && time() - EnteredCurrentStatus > '+str(thresholdGoodJobs),["ClusterId", "ProcId"])
      numRunningLong = 0
      for job in jobs:
         numRunningLong = numRunningLong + 1

      # if there are some jobs probably running real work, submit more jobs
      if numRunningLong > 0:
         numToSubmit = 2

      # get number of running jobs
      numRunning = 1
      jobs = schedd.query('RequiresVac =?= True && Cmd == "'+label+'" && JobStatus == 2',["ClusterId", "ProcId"])
      numRunning = 0
      for job in jobs:
         numRunning = numRunning + 1

      log("Idle VMs = "+str(numIdle)+"; Running VMs = "+str(numRunning)+"; Long running VMs = "+str(numRunningLong))

      # submit jobs if necessary (don't if too many are already idle)
      if (numIdle < maxIdleJobs and numRunningLong > thresholdNumGoodJobs) or (numIdle + numRunning < maxJobsAfterWaiting and numRunningLong == 0):
         for i in range (0, numToSubmit):
            p = subprocess.Popen(["condor_submit", submitScript], stdout=subprocess.PIPE)
            output, err = p.communicate()
            log(output)
      else:
         log("Not submitting as there are "+str(numIdle)+" idle VMs")

   time.sleep(runEvery)
 
sys.exit(42)

