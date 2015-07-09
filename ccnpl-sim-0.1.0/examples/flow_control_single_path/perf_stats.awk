#!/bin/awk -f

BEGIN{}
{
#&& ($1>3.6e+09)
	if (( $2 == "closed")){
                #print "node " $4;
		if (!($4 in nodes)){
			nodes[$4] = 1;
			n_node++;
		}
		if (!($11 in classes)){
			if ($11 <= 20){
				classes[$10] = 1;
				n_classes++;
			}
		}
		tot_class++;
		if ($11 <= 20){ 
			VRTT[$4,$11] += $8;
			delay[$4,$11] += $9;
			win[$4,$11] += $14;
			completion_time[$4,$11] += $6;
			throughput[$4,$11] += ($7/$6);
			file_size[$4,$11] += ($7);
			sample[$4,$11] ++;
			throughput_i[$4,$11,sample[$4,$11]] = ($7/$6)
		}
	}
}
END{
	for(i in nodes){
		for (j=1;j<=20;j++){
			if (sample[i,j]!=0){
				print completion_time[i,j]/sample[i,j] " class " j " " > "perf_node"i".log";
			}
			else
				print 0 " class " j " " > "perf_node"i".log";
		} 
	}
}
