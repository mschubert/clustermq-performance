# This is to compare clustermq performance compared to batchtools
#
# Testing overhead:
#  * Vector of numeric (length n), each call multiplies by 2
#  * 1e3 .. 1e8 calls
#  * 10 or 100 jobs

clustermq = function(fx, input, n_calls=1e3, n_jobs=10) {
    tt = proc.time()
    result = clustermq::Q(fx, x=input, n_jobs=n_jobs, memory=512, rettype="numeric")
    tt = proc.time() - tt
    list(result=result, time=tt)
}

batchtools = function(fx, input, n_calls=1e3, n_jobs=10) {
    tt = proc.time()
    reg = batchtools::makeRegistry(file.dir=tempfile())
#    reg$cluster.functions = batchtools::makeClusterFunctionsLSF(template="batchtools_lsf.tmpl")
    reg$cluster.functions = batchtools::makeClusterFunctionsSlurm(template="batchtools_slurm.tmpl")
    result = batchtools::btlapply(input, fx, n.chunks=n_jobs, reg=reg)
    tt = proc.time() - tt
    list(result=result, time=tt)
}

BatchJobs = function(fx, input, n_calls=1e3, n_jobs=10) {
    library(BatchJobs) # read .BatchJobs.R in olddir
    olddir = getwd()
    setwd(Sys.getenv("TMPDIR"))

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

    list(result=result, time=tt)
}

overhead = function(pkg, n_calls, n_jobs, rep) {
    args = list(fx = function(x) x*2,
                input = runif(n_calls),
                n_calls=as.integer(n_calls),
                n_jobs=as.integer(n_jobs))

    re = do.call(pkg, args)
    stopifnot(simplify2array(re$result) - args$input*2 < .Machine$double.eps)
    re$tt
}

ARGS = strsplit(commandArgs(TRUE)[1], "[/-]")[[1]]
OUTFILE = commandArgs(TRUE)[2]

print(ARGS)
times = do.call(ARGS[1], as.list(ARGS[-1]))
save(times, file=OUTFILE)
