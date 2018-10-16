exp = $(shell seq 3 9) # seq 3 9 for full range; reduce for testing
n_calls = $(exp:%=1e%)
n_jobs = 10 50
rep = 1 2
pkg = BatchJobs batchtools clustermq
fun = overhead

combinations = \
	$(foreach f, $(fun), \
		$(foreach p, $(pkg), \
			$(foreach c, $(n_calls), \
				$(foreach j, $(n_jobs), \
					$(foreach r, $(rep), \
						$f/$p-$c-$j-$r)))))

files = $(shell shuf -e $(combinations:%=%.RData) | \
	grep -v batchtools-1e[789] | \
	grep -v BatchJobs-1e[6789])

plot.png: plot.pdf
	convert -density 400 -resize 25% $< $@

plot.pdf: plot.r $(files)
	Rscript plot.r $@ $(files)

$(files): %.RData: run.r
	@mkdir -p $(dir $@)
	TMPDIR=./tmp Rscript $^ $* $@
