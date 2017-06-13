#!/bin/bash

# feito para ser usado apenas dentro do container docker
cd /src;
source /home/app/perl5/perlbrew/etc/bashrc
CATALYST_CONFIG=/src/iota.conf perl script/emails_queue_sender.pl 1>>/data/log/email.log 2>>/data/log/email.error.log
