#!/bin/bash
main=./waf

SCRIPTPATH=`pwd`
sim="NDNSIM"

runs=9
logDir=logs
infoDir=infoSim
#net=`grep 'net=' $iniFile | awk '{print $3}' | awk -F '=' '{print $2}' | awk -F '}' '{print $1}'`

net=single_cache
T=SINGLE_CACHE
#A=1
plateau=0
C=0.01
M=10000
#L=200
#simDuration=5000
req=1000000

for k in 0.6
do
	for z in 25 50 75 100 
   	do
		let "simDuration = $req / $z"
		#simDuration=`expr $req/$z`
echo $simDuration
		let "realReq = $simDuration * $z"
echo $realReq
     		#realReq=$simDuration*$z
      		echo $realReq > $logDir/req_L\=${z}_A\=${k} 
      		for i in `seq 0 $runs`
      		do
         		j=`expr $i + 1`
   
         		/usr/bin/time -f "\n%E \t elapsed real time \n%U \t total CPU seconds used (user mode) \n%S \t total CPU seconds used by the system on behalf of the process \n%M \t memory (max resident set size) [kBytes] \n%x \t exit status" -o ${infoDir}/Info_SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R\=${i}.txt $main --run "scratch/ndn-single-cache-cs-tracers_NEW --catalogCardinality\=${M} --numReqTot\=${req} --cacheToCatalogRatio\=${C} --lambda\=${z} --alpha\=${k} --plateau\=${plateau} --simType\=${T} --simDuration\=${simDuration} --RngSeed\=1 --RngRun\=${j}" > $logDir/stdout/SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R\=${i}.out 2>&1   

        		# grep 'Hit_Event' $logDir/SIM\=${sim}_T\=${T}_M\=${M}_C\=${C}_L\=${L}_A\=${A}_R\=${i}-temp.out > $logDir/SIM\=${sim}_T\=${T}_M\=${M}_C\=${C}_L\=${L}_A\=${A}_R\=${i}.out
   
        		# rm $logDir/SIM\=${sim}_T\=${T}_M\=${M}_C\=${C}_L\=${L}_A\=${A}_R\=${i}-temp.out 
      		done

      		tar -zcvf $logDir/log_${req}_req_SIM\=${sim}_T\=${T}_M\=${M}_C\=${C}_L\=${z}_A\=${k}.tar.gz $logDir/SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R*
      		rm $logDir/SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R*

      		tar -zcvf $infoDir/Info_${req}_req_SIM\=${sim}_T\=${T}_M\=${M}_C\=${C}_L\=${z}_A\=${k}.tar.gz $infoDir/Info_SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R*
      		rm $infoDir/Info_SIM\=${sim}_T\=${T}_REQ\=${req}_M\=${M}_C\=${C}_L\=${z}_A\=${k}_R*
   	done
done
