# This is to compare clustermq performance compared to batchtools
#
# Testing overhead:
#  * Vector of numeric (length n), each call multiplies by 2
#  * 1e3 .. 1e8 calls
#  * 10 or 100 jobs

clustermq = function(fun, ..., const=list(), n_jobs=10) {
    #TODO: rettype="numeric" if parent.frame is overhead
    tt = proc.time()
    result = clustermq::Q(fun, ..., const=const, n_jobs=n_jobs, memory=512)
    tt = proc.time() - tt
    list(result=result, time=tt)
}

batchtools = function(fun, ..., const=list(), n_jobs=10) {
    tt = proc.time()
    reg = batchtools::makeRegistry(file.dir=tempfile())
#    reg$cluster.functions = batchtools::makeClusterFunctionsLSF(template="batchtools_lsf.tmpl")
    reg$cluster.functions = batchtools::makeClusterFunctionsSlurm(template="batchtools_slurm.tmpl")
    result = batchtools::btmapply(fun, ..., more.args=const, n.chunks=n_jobs, reg=reg)
    tt = proc.time() - tt
    list(result=result, time=tt)
}

BatchJobs = function(fun, ..., const=list(), n_jobs=10) {
    library(BatchJobs) # read .BatchJobs.R in olddir
    olddir = getwd()
    setwd(Sys.getenv("TMPDIR"))

    tt = proc.time()
    reg = BatchJobs::makeRegistry(id=basename(tempdir()))
    BatchJobs::batchMap(reg=reg, fun=fun, ..., more.args=const)
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
    args = list(fun = function(x) x*2,
                x = runif(n_calls),
                n_jobs=as.integer(n_jobs))

    re = do.call(pkg, args)
    stopifnot(simplify2array(re$result) - args$x*2 < .Machine$double.eps)
    re$tt
}

bem = function(pkg, n_calls, n_jobs, rep) {
    fun = function(cohort, drug, feat, bem, ic50s, tissues) {
        if (cohort == "pan")
            subs = rep(TRUE, length(tissues))
        else
            subs = tissues == cohort
        resp = ic50s[subs, drug]
        feats = bem[subs, feat]
        if (sum(feats[!is.na(resp)]) >= 2)
            broom::tidy(lm(resp ~ feats))
        else
            c()
    }

    gdsc = import('data/gdsc')
    tissues = gdsc$tissues(minN=10)
    ic50s = gdsc$drug_response()
    bem = gdsc$bem()
    narray::intersect(tissues, ic50s, bem, along=1)

    idx = expand.grid(cohort=c("pan", unique(tissues)), drug=colnames(ic50s),
                      feat=colnames(bem), stringsAsFactors=FALSE)
    idx = idx[sample(seq_len(nrow(idx)), n_calls, replace=TRUE),]

    re = pkg(fun=fun, cohort=idx$cohort, drug=idx$drug, feat=idx$feat,
             n_jobs=as.integer(n_jobs),
             const = list(ic50s=ic50s, tissues=tissues, bem=bem))
}

ARGS = strsplit(commandArgs(TRUE)[1], "[/-]")[[1]]
OUTFILE = commandArgs(TRUE)[2]

print(ARGS)
times = do.call(ARGS[1], as.list(ARGS[-1]))
save(times, file=OUTFILE)
