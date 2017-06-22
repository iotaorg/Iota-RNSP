#!/bin/bash

# feito para ser usado apenas dentro do container docker
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
mkdir -p /data/envdir

CATALYST_CONFIG=/src/iota.conf start_server \
 --pid-file=/tmp/start_server.pid \
 --envdir=/data/envdir \
 --signal-on-hup=QUIT \
 --kill-old-delay=10 \
 --port=8080 \
 -- starman --workers 4 --error-log /data/log/starman.log -MCatalyst -MDBIx::Class --user app --group app iota.psgi 
