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
