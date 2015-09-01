#!/bin/sh
len7="2500e+03"
wtu="1e-06"
file1="catalog_zipf_1e4_1.dist"
prefix="prefix_single_cache.dist"
clients="clients_single_cache.dist"

infoDir=infoSim/R_1e7
optionDir=option_files/R_1e7

T="SINGLE_CACHE"
C=0.01
M=10000
req=10000000
alpha=1
lam=4

runs=0


for i in `seq 0 $runs`
do
   /usr/bin/time -f "\n%E \t elapsed real time \n%U \t total CPU seconds used (user mode) \n%S \t total CPU seconds used by the system on behalf of the process \n%M \t memory (max resident set size) [kBytes] \n%x \t exit status"  -o ${infoDir}/R_1e7/Info_SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${lam}_A\=${alpha}_R\=${i}.txt  ../ccnpl-sim/bin/cbcbsim -input ${optionDir}/option_file_single_cache_1e4_1e7_${alpha}_${i} > stderr_single_cache_1e4_1e7_${alpha}_${i}.log 2>&1
done
