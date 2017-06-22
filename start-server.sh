#!/bin/bash

# feito para ser usado apenas dentro do container docker
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
KILL_OLD_DELAY=5 CATALYST_CONFIG=/src/iota.conf start_server --port 8080 -- starman --workers 4 --error-log /data/log/starman.log --user app --group app iota.psgi 
