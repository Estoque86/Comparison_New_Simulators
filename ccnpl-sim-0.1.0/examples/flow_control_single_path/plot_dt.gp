reset

set term post color eps enh  "Times-Roman" 32
set key right bottom
set key vertical Left
set xlabel "Object class k"
set ylabel "Delivery time [s]" 
set xrange[0:20]
set xtics 5
set grid x
set grid y
set pointsize 1.8
set output "delivery_t.eps"



plot 'perf_node2.log' u ($3):($1)w lp lw 4 lc 3 lt 1  pt 4 notitle

