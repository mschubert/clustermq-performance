#!/bin/sh

cd $(dirname $0)

rsync -auvr \
    --exclude '.git' \
    --include '*.RData' \
    --include '*.pdf' \
    --exclude '*.r' \
    --exclude '*.tmpl' \
    yoda:/hps/nobackup/saezrodriguez/mike/clustermq-performance/* .
