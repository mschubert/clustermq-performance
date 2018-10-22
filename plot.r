library(dplyr)
library(ggplot2)

load_file = function(fname) {
    env = new.env()
    load(fname, env)
    
    fields = strsplit(sub("\\.RData$", "", fname), "[/-]")[[1]] %>%
        as.list() %>%
        setNames(c("fun", "pkg", "n_calls", "n_jobs", "rep"))

    fields$times = list(do.call(data.frame, as.list(env$times)))
    fields
}

OUTFILE = commandArgs(TRUE)[1]
INFILES = commandArgs(TRUE)[-1]

if (length(INFILES) == 0)
    INFILES = c(list.files("overhead", recursive=TRUE, full.names=TRUE),
                list.files("overhead", recursive=TRUE, full.names=TRUE))

if (is.na(OUTFILE))
    OUTFILE = "plot.pdf"

times = lapply(INFILES, load_file) %>%
    bind_rows() %>%
    mutate(n_calls = as.numeric(n_calls)) %>%
    tidyr::unnest() %>%
    group_by(fun, pkg, n_calls, n_jobs) %>%
    summarize(mt = mean(elapsed),
              sdt = sd(elapsed)) %>%
    ungroup()

p = ggplot(times, aes(x=n_calls, y=mt, shape=n_jobs, color=pkg, linetype=n_jobs)) +
    geom_errorbar(aes(ymin=mt-sdt, ymax=mt+sdt), width=.1, size=1, position=position_dodge(0.05)) +
    geom_line(size=1.1, alpha=0.8) +
    geom_point(size=3)+
    scale_y_continuous(trans = "log10",
#                       limits = c(0.5, 9e4),
                       breaks = c(1, 5, 30, 60, 300, 1800, 3600, 18000, 43200, 86400),
                       labels = c("1 second", "5 s", "30 s", "1 minute", "5 min", "30 min", "1 hour", "5 h", "12 h", "1 day")) +
    scale_x_continuous(trans = "log10",
                       breaks = unique(times$n_calls),
                       labels = sub("\\+0", "", sprintf("%.0e", unique(times$n_calls)))) +
    scale_color_discrete(labels=c(paste("BatchJobs", packageVersion("BatchJobs")),
                                  paste("batchtools", packageVersion("batchtools")),
                                  paste("clustermq", packageVersion("clustermq")))) +
    labs(title = "Processing overhead",
         x = "Number of function calls",
         y = "Runtime") +
    guides(color = guide_legend(title="Package"),
           shape = guide_legend(title="Number of jobs"),
           linetype = guide_legend(title="Number of jobs")) +
    theme_classic() +
    theme(axis.text = element_text(size=11)) +
    facet_wrap(~ fun)

pdf(OUTFILE, width=10, height=4)
print(p)
dev.off()
