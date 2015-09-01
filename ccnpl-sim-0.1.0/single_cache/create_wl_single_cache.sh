#!/bin/sh


#in topology file fileds 4,5 and 6 of the edge's list are: buffer size[kbit], propagation delay[unit measure depend on $3] and edge capacity[kbps]


len6="250e+03"
len7="2500e+03"
len8="25000e+03"
wtu="1e-06"
file1="catalog_zipf_1e4_08.dist"
file2="catalog_zipf_1e4_1.dist"
file3="catalog_zipf_1e4_12.dist"
prefix="prefix.dist"
clients="clients.dist"
out11="workload_1e4_1e6_08.wl"
out12="workload_1e4_1e6_1.wl"
out13="workload_1e4_1e6_12.wl"
out21="workload_1e4_1e7_08.wl"
out22="workload_1e4_1e7_1.wl"
out23="workload_1e4_1e7_12.wl"
out31="workload_1e4_1e6_08.wl"
out32="workload_1e4_1e6_1.wl"
out33="workload_1e4_1e6_12.wl"

../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len6 -wtu $wtu -man_routing -files $file1 -prefix $prefix -clients $clients > $out11
../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len6 -wtu $wtu -man_routing -files $file2 -prefix $prefix -clients $clients > $out12
../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len6 -wtu $wtu -man_routing -files $file3 -prefix $prefix -clients $clients > $out13

../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len7 -wtu $wtu -man_routing -files $file1 -prefix $prefix -clients $clients > $out21
../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len7 -wtu $wtu -man_routing -files $file2 -prefix $prefix -clients $clients > $out22
../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len7 -wtu $wtu -man_routing -files $file3 -prefix $prefix -clients $clients > $out23

../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len8 -wtu $wtu -man_routing -files $file1 -prefix $prefix -clients $clients > $out31
../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len8 -wtu $wtu -man_routing -files $file2 -prefix $prefix -clients $clients > $out32
../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len8 -wtu $wtu -man_routing -files $file3 -prefix $prefix -clients $clients > $out33
