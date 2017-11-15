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
#        "#BSUB-q highpri",
        "Rscript -e 'batchtools::doJobCollection(\"<%= uri %>\")'")

    tt = proc.time()
    reg = batchtools::makeRegistry(file.dir=tempfile(tmpdir=tmpdir))
    reg$cluster.functions = batchtools::makeClusterFunctionsLSF(template = tmpl)
    result = batchtools::btlapply(input, fx, n.chunks=n_jobs, reg=reg)
    tt = proc.time() - tt

    stopifnot(simplify2array(input)*2 == result)
    tt
}

overhead = function(fun, n_calls, n_jobs, rep) {
    do.call(fun, list(n_calls=as.integer(n_calls), n_jobs=as.integer(n_jobs)))
}

ARGS = strsplit(commandArgs(TRUE)[1], "-")[[1]]
OUTFILE = commandArgs(TRUE)[2]

print(ARGS)
times = do.call(overhead, as.list(ARGS))

save(times, file=OUTFILE)
