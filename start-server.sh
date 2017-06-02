#!/bin/bash

# feito para ser usado apenas dentro do container docker
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
starman --port 8080 --workers 4 --error-log /data/log/starman.log --user app --group app iota.psgi 
