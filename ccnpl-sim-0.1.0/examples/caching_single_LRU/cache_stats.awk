#!/bin/awk -f
BEGIN{
	starting = 0;
	miss_rate = 0;
	hit_rate = 0;
	request_rate = 0;
	miss_prob = 0;
	hit_prob = 0;
	filter_prob = 0;
	old_node = 0;
	old_class = 0;
	out_rate = 0;
	chunk_counter = 0;
	nodes=0;
} 
{
        if (($1=="CACHE")&&($2=="FINAL")&&($3=="NODE")){
		miss_rate = $5;
		hit_rate = $6;
		request_rate = $7;
		miss_prob = $8;
		hit_prob = $9;
		filter_prob = $10;
		out_rate = $11;
		node=$4;
		old_class = $13;
		node=$4;
		print "NODE " node " " $7 " " $11 "  class " old_class " " > "CACHE" node".log";
	}
}
END{}
