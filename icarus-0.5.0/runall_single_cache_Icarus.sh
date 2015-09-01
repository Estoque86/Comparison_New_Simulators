#!/bin/sh

sim="ICARUS"
logDir=logs
infoDir=infoSim

resultFile=results_Single_Cache
configFile=config_Single_Cache.py

T="SINGLE_CACHE"
C=0.01
M=10000
req=1000000
alpha=0.8
lam=4

runs=9

for i in `seq 0 $runs`
do
   /usr/bin/time -f "\n%E \t elapsed real time \n%U \t total CPU seconds used (user mode) \n%S \t total CPU seconds used by the system on behalf of the process \n%M \t memory (max resident set size) [kBytes] \n%x \t exit status"  -o ${infoDir}/Info_SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${lam}_A\=${alpha}_R\=${i}.txt  python icarus.py --results ${resultFile}_REQ\=${req}_M\=${M}_C\=${C}_L\=${lam}_A\=${alpha}_R\=${i}.pickle ${configFile} > ${logDir}/stdout/SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R\=${i}.out 2>&1
done


#`awk -v v1="${alphaLineStart}" -v v2="${j}" '$1==v1{$4='v2'}{print $0}' icarus/config.py > icarus/config_temp.py`
#`mv icarus/config_temp.py icarus/config.py`
#net=`grep '^TOPOLOGIES' icarus/config.py | awk '{print $3}' | awk -F "'" '{print $2}'`
#C=`grep '^NET_CACHE' icarus/config.py | awk '{print $3}' | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'`
#S=`grep '^STRATEGIES' icarus/config.py | awk '{print $3}' | awk -F "'" '{print $2}'`
#a=`grep '^ALPHA' icarus/config.py | awk '{print $4}'`
##a=`grep '^ALPHA' icarus/config.py | awk '{print $3}' | awk -F '[' '{print $2}' | awk -F ']' '{print $1}'`
#L=`grep '^RATE' icarus/config.py | awk -F ' ' '{print $3}'`
#M=`grep '^N_CONTENTS' icarus/config.py | awk -F ' ' '{print $3}'`