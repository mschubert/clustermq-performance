exp = $(shell seq 3 8)
n_calls = $(exp:%=1e+%)
n_jobs = 10 50
rep = 1
fun = overhead_batchtools overhead_cmq

combinations = \
	$(foreach f, $(fun), \
		$(foreach c, $(n_calls), \
			$(foreach j, $(n_jobs), \
				$(foreach r, $(rep), \
					$f-$c-$j-$r))))

# filter out batchtools >= 1e7 calls, this just takes too long
discard = overhead_batchtools-1e+7% overhead_batchtools-1e+8%
targets = $(filter-out $(discard), $(combinations))
files = $(targets:%=%.RData)

all: $(files)

$(files): %.RData: run.r
	Rscript $^ $* $@
