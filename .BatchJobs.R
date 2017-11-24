# https://github.com/tudo-r/BatchJobs/wiki/Configuration
cluster.functions = makeClusterFunctionsLSF("BatchJobs.tmpl")
staged.queries = TRUE
debug = FALSE
db.options = list(pragmas = c("busy_timeout=5000", "journal_mode=WAL"))
