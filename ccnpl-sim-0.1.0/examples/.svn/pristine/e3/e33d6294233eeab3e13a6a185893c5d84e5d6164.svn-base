cat outputfile | awk -f cache_stats.awk
gnuplot plot_pmiss.gp
cat stderr.log | awk -f perf_stats.awk
gnuplot plot_dt.gp
