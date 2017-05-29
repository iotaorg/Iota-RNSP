#!/bin/bash -xe


export USER=app

curl -L http://xrl.us/perlbrewinstall | bash;
echo 'source /home/app/perl5/perlbrew/etc/bashrc' >> /home/app/.bashrc;

source /home/app/perl5/perlbrew/etc/bashrc

perlbrew install -n -j 8 perl-5.22.2
perlbrew install-cpanm
perlbrew switch perl-5.22.2