reset

set term post color eps enh  "Times-Roman" 32
set key right bottom
set key vertical Left
set xlabel "Object class k"
set ylabel "Miss probability" 
set yrange[0:1]
set xrange[0:20]
set xtics 5
set grid x
set grid y
set pointsize 1.8
set output "pmiss.eps"



plot 'CACHE4.log' u ($6):($4/$3)w lp lw 4 lc 0 lt 1  pt 4 title " CACHE 4" ,\
     'CACHE8.log' u ($6):($4/$3)w lp lw 4 lc 1 lt 1  pt 6 title " CACHE 8",\
     'CACHE10.log' u ($6):($4/$3)w lp lw 4 lc 2 lt 1  pt 8 title " CACHE 10" 

