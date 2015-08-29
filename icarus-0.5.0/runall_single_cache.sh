#!/bin/sh

sim=ICARUS
alphaLineStart="ALPHA"
runs=0
scenarioFile=run_new.py
infoDir=infoSim
logDir=logs
req=1000000

for j in 0.6 
do
   `awk -v v1="${alphaLineStart}" -v v2="${j}" '$1==v1{$4='v2'}{print $0}' icarus/config.py > icarus/config_temp.py`
   `mv icarus/config_temp.py icarus/config.py`

   net=`grep '^TOPOLOGIES' icarus/config.py | awk '{print $3}' | awk -F "'" '{print $2}'`
   C=`grep '^NET_CACHE' icarus/config.py | awk '{print $3}' | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'`
   S=`grep '^STRATEGIES' icarus/config.py | awk '{print $3}' | awk -F "'" '{print $2}'`
   a=`grep '^ALPHA' icarus/config.py | awk '{print $4}'`
   #a=`grep '^ALPHA' icarus/config.py | awk '{print $3}' | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'`
   L=`grep '^RATE' icarus/config.py | awk -F ' ' '{print $3}'`
   M=`grep '^N_CONTENTS' icarus/config.py | awk -F ' ' '{print $3}'`

   for i in `seq 0 $runs`
   do
      /usr/bin/time -f "\n%E \t elapsed real time \n%U \t total CPU seconds used (user mode) \n%S \t total CPU seconds used by the system on behalf of the process \n%M \t memory (max resident set size) [kBytes] \n%x \t exit status" -o ${infoDir}/Info_SIM\=${sim}_T\=${net}_REQ\=${req}_M\=${M}_C\=${C}_L\=${L}_A\=${a}_R\=${i}.txt python icarus/${scenarioFile} $i 
      #rm ${logDir}/RESULTS*
   done

   tar -zcvf $logDir/log_${req}_req_SIM\=${sim}_T\=${net}_M\=${M}_C\=${C}_L\=${L}_A\=${a}.tar.gz $logDir/SIM\=${sim}_T\=${net}_REQ\=${req}_M\=${M}_C\=${C}_L\=${L}_A\=${a}_R*
   rm $logDir/SIM\=${sim}_T\=${net}_REQ\=${req}_M\=${M}_C\=${C}_L\=${L}_A\=${a}_R*

   tar -zcvf $infoDir/Info_${req}_req_SIM\=${sim}_T\=${net}_M\=${M}_C\=${C}_L\=${L}_A\=${a}.tar.gz $infoDir/Info_SIM\=${sim}_T\=${net}_REQ\=${req}_M\=${M}_C\=${C}_L\=${L}_A\=${a}_R*
   rm $infoDir/Info_SIM\=${sim}_T\=${net}_REQ\=${req}_M\=${M}_C\=${C}_L\=${L}_A\=${a}_R*

done

