exp = $(shell seq 3 8)
n_calls = $(exp:%=1e%)
n_jobs = 10 50
rep = 1 2
fun = batchtools cmq BatchJobs

combinations = \
	$(foreach f, $(fun), \
		$(foreach c, $(n_calls), \
			$(foreach j, $(n_jobs), \
				$(foreach r, $(rep), \
					$f-$c-$j-$r))))

files = $(shell shuf -e $(combinations:%=times/%.RData) | \
	grep -v batchtools-1e[78] | \
	grep -v BatchJobs-1e[678])

plot.pdf: plot.r $(files)
	Rscript plot.r $@ $(files)

$(files): times/%.RData: run.r
	@mkdir -p $(dir $@)
	Rscript $^ $* $@
