#!/bin/bash

sim="ndnSIM"

runs=1
logDir=logs/stdout
T=SINGLE_CACHE
#A=1
plateau=0
C=0.01
M=10000
lam=4
#simDuration=5000
#req=1000000


    let "simDuration = $req / $lam"
    echo $simDuration
    let "realReq = $simDuration * $lam"
    echo $realReq
    
for alpha in 1
do
  for req in 1000000
  do
    for run in `seq 0 $runs`
    do
      for cont in `seq 1 $M`
      do
        grep -P "^HIT \t"$cont"$" $logDir/SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${lam}_A\=${alpha}_R\=${run}.out | wc -l >> temp_hit_${run}.out
        
        grep -P "^HIT \t"$cont"$|^MISS \t"$cont"$" $logDir/SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${lam}_A\=${alpha}_R\=${run}.out | wc -l >> temp_tot_${run}.out
      done
    done
  done
done
