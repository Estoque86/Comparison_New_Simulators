cat stderr.log | awk -f perf_stats.awk
gnuplot plot_dt.gp
