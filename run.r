library(dplyr)
# This is to compare clustermq performance compared to batchtools
#
# Test cases are:
#
# Overhead
#  * Vector of numeric (length n), each call multiplies by 2
#  * 1e3 .. 1e8 calls
#  * 10 or 100 jobs
#
# .. which other test cases? .. [GDSC drug sensi ML?]

#TODO: have functions take a list of vectors
#  vectors are 1b, 1Kb, 1Mb
#  either multiply (same length) or summarize them (length=1)
#    where summarize is better for batchtools, lower reads on reduce
#    maybe I can get away with only doing summarize
overhead_cmq = function(n_calls=1e3, n_jobs=10, ...) {
    input = runif(n_calls)
    fx = function(x) x*2

    tt = proc.time()
    result = clustermq::Q(fx, x = input, n_jobs = n_jobs, memory = 512, wait_time=0, ...)
    tt = proc.time() - tt

    stopifnot(simplify2array(input)*2 == result)
    tt
}

overhead_batchtools = function(n_calls=1e3, n_jobs=10) {
    tmpdir = "/hps/nobackup/saezrodriguez/mike/tmp" # shared between nodes
    input = runif(n_calls)
    fx = function(x) x*2

    tmpl = paste(sep="\n",
        "#BSUB-J <%= job.name %>",
        "#BSUB-o /dev/null",
        "#BSUB-M 512",
        "#BSUB-R rusage[mem=512]",
        "#BSUB-q highpri",
        "Rscript -e 'batchtools::doJobCollection(\"<%= uri %>\")'")

    tt = proc.time()
    reg = batchtools::makeRegistry(file.dir=tempfile(tmpdir=tmpdir))
    reg$cluster.functions = batchtools::makeClusterFunctionsLSF(template = tmpl)
    result = batchtools::btlapply(input, fx, n.chunks=10*n_jobs, reg=reg)
    tt = proc.time() - tt

    stopifnot(simplify2array(input)*2 == result)
    tt
}

overhead = function(n_calls, n_jobs, fun, ...) {
    do.call(fun, list(n_calls=n_calls, n_jobs=n_jobs))
}

ARGS = strsplit(commandArgs(TRUE)[1], "-")
OUTFILE = commandArgs(TRUE)[2]


tdf = expand.grid(n_calls = 10^(2:8), n_jobs=c(10, 50), rep=1:1,
        fun = c("overhead_cmq", "overhead_batchtools"),
        stringsAsFactors=FALSE) %>%
    filter(!(fun == "overhead_batchtools" & n_calls >= 1e7))
tdf = tdf[sample(1:nrow(tdf)),]

tdf
tdf$times = purrr::pmap(tdf, overhead)

result = tdf %>%
    mutate(elapsed = sapply(times, function(x) x[['elapsed']])) %>%
    group_by(fun, n_calls, n_jobs) %>%
    summarize(mt = mean(elapsed),
              sdt = sd(elapsed))

library(ggplot2)
ggplot(result, aes(x=n_calls, y=mt, group=fun, shape=fun, linetype=fun)) + 
    geom_errorbar(aes(ymin=mt-sdt, ymax=mt+sdt), width=.1, 
    position=position_dodge(0.05)) +
    geom_line() +
    geom_point()+
    labs(title="Plot of lengthby dose", x="Dose (mg)", y="Length") +
    theme_classic()
