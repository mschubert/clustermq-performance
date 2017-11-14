library(dplyr)

OUTFILE = commandArgs(TRUE)[1]

tdf = expand.grid(n_calls = 10^(2:8), n_jobs=c(10, 50), rep=1:1,
        fun = c("overhead_cmq", "overhead_batchtools"),
        stringsAsFactors=FALSE) %>%
    filter(!(fun == "overhead_batchtools" & n_calls >= 1e7))

write.table(tdf, file=OUTFILE, sep="\t", quote=FALSE)
