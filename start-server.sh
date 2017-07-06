#!/bin/bash

# script feito para ser usado apenas dentro do container docker

# OBS: só da para mudar workers de maneira persistente matando o start_server com INT, 
# logo, o restart deixa de ser graceful, entao escolha com cuidado
# Atualmente iota usa aprox 200mb ~ 350mb de Memoria RAM por worker
export WORKERS=4

cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
mkdir -p /data/envdir

CATALYST_CONFIG=/src/iota.conf start_server \
 --pid-file=/tmp/start_server.pid \
 --envdir=/data/envdir \
 --signal-on-hup=QUIT \
 --kill-old-delay=10 \
 --port=8080 \
 -- starman \
 	--workers $WORKERS \
 	--error-log /data/log/starman.log \
 	-MCatalyst -MDBIx::Class -MJSON::XS -MMoose \
 	--user app --group app iota.psgi 
