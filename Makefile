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

# filter out batchtools >= 1e7 calls, this just takes too long
discard = batchtools-1e+7% batchtools-1e+8%
targets = $(filter-out $(discard), $(combinations))
files = $(shell shuf -e $(targets:%=times/%.RData))

plot.pdf: plot.r $(files)
	Rscript plot.r $@ $(files)

$(files): times/%.RData: run.r
	@mkdir -p $(dir $@)
	Rscript $^ $* $@
