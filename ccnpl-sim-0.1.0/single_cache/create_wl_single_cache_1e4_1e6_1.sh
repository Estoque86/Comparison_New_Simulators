#!/bin/sh


#in topology file fileds 4,5 and 6 of the edge's list are: buffer size[kbit], propagation delay[unit measure depend on $3] and edge capacity[kbps]


len6="250e+03"
wtu="1e-06"
file1="catalog_zipf_1e4_1.dist"
prefix="prefix_single_cache.dist"
clients="clients_single_cache.dist"
infoDir=infoSim
wlDir=workload

T="SINGLE_CACHE"
C=0.01
M=10000
req=1000000
alpha=1
lam=4

runs=1

for i in `seq 0 $runs`
do
   /usr/bin/time -f "\n%E \t elapsed real time \n%U \t total CPU seconds used (user mode) \n%S \t total CPU seconds used by the system on behalf of the process \n%M \t memory (max resident set size) [kBytes] \n%x \t exit status"  -o ${infoDir}/Info_SIM_WL\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${lam}_A\=${alpha}_R\=${i}.txt  ../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len6 -wtu $wtu -man_routing -files $file1 -prefix $prefix -clients $clients  > ${wlDir}/workload_1e4_1e6_1_${i}.wl 2>&1
done