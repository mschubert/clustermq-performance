# This is to compare clustermq performance compared to batchtools
#
# Testing overhead:
#  * Vector of numeric (length n), each call multiplies by 2
#  * 1e3 .. 1e8 calls
#  * 10 or 100 jobs

clustermq = function(n_calls=1e3, n_jobs=10, ...) {
    input = runif(n_calls)
    fx = function(x) x*2

    tt = proc.time()
    result = clustermq::Q(fx, x = input, n_jobs = n_jobs, memory = 512, wait_time=0, ...)
    tt = proc.time() - tt

    stopifnot(simplify2array(result) - input*2 < .Machine$double.eps)
    tt
}

batchtools = function(n_calls=1e3, n_jobs=10) {
    tmpdir = "/hps/nobackup/saezrodriguez/mike/tmp" # shared between nodes
    input = runif(n_calls)
    fx = function(x) x*2

    tmpl = paste(sep="\n",
        "#BSUB-J <%= job.name %>",
        "#BSUB-o /dev/null",
        "#BSUB-M 512",
        "#BSUB-R rusage[mem=512]",
        "Rscript -e 'batchtools::doJobCollection(\"<%= uri %>\")'")

    tt = proc.time()
    reg = batchtools::makeRegistry(file.dir=tempfile(tmpdir=tmpdir))
    reg$cluster.functions = batchtools::makeClusterFunctionsLSF(template = tmpl)
    result = batchtools::btlapply(input, fx, n.chunks=n_jobs, reg=reg)
    tt = proc.time() - tt

    stopifnot(simplify2array(result) - input*2 < .Machine$double.eps)
    tt
}

BatchJobs = function(n_calls=1e3, n_jobs=10) {
    tmpdir = "/homes/schubert/tmp" # shared between nodes
    input = runif(n_calls)
    fx = function(x) x*2

    library(BatchJobs) # read .BatchJobs.R in olddir
    olddir = getwd()
    setwd(tmpdir)

    tt = proc.time()
    reg = BatchJobs::makeRegistry(id=basename(tempdir()))
    BatchJobs::batchMap(reg=reg, fun=fx, input)
    ids = BatchJobs::getJobIds(reg)
    ids = BBmisc::chunk(ids, n.chunks=n_jobs)
    BatchJobs::submitJobs(reg, ids, job.delay=TRUE, max.retries=Inf)
    BatchJobs::waitForJobs(reg, ids=BatchJobs::getJobIds(reg))
    result = reduceResultsList(reg, fun=function(job, res) res)
    unlink(reg$file.dir, recursive=TRUE)
    tt = proc.time() - tt
    setwd(olddir)
    
    stopifnot(simplify2array(result) - input*2 < .Machine$double.eps)
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
