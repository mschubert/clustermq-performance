# https://github.com/tudo-r/BatchJobs/wiki/Configuration
cluster.functions = makeClusterFunctionsSLURM("BatchJobs_slurm.tmpl")
#cluster.functions = makeClusterFunctionsLSF("BatchJobs_lsf.tmpl")
staged.queries = TRUE
debug = FALSE
db.options = list(pragmas = c("busy_timeout=5000", "journal_mode=WAL"))
