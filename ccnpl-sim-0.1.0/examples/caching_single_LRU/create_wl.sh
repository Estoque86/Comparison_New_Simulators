#!/bin/sh


#in topology file fileds 4,5 and 6 of the edge's list are: buffer size[kbit], propagation delay[unit measure depend on $3] and edge capacity[kbps]


len="1000e+03"
wtu="1e-06"
files="final_names20000_constsize.dist"
prefix="prefix.dist"
clients="clients.dist"
out="my.wl"
../../ccnpl-sim/cbnsim/bin/cbnwlgen -l $len -wtu $wtu -man_routing -files $files -prefix $prefix -clients $clients > $out

