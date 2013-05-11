#!/bin/bash
# cpanm Server::Starter

PORT=5000
# This should be the directory name/app name
APP="iota"
PIDFILE="$HOME/app/$APP.pid"
STATUS="$HOME/app/$APP.status"

DAEMON="$HOME/perl5/perlbrew/perls/perl-5.16.3/bin/start_server"

# The actual path on disk to the application.
APP_HOME="/home/iota/app/backend"

# How many workers
WORKERS=5

# This is only relevant if using Catalyst
TDP_HOME="$APP_HOME"
export TDP_HOME

ERROR_LOG="$HOME/app/logs/$APP.error.log"

STARMAN="starman --preload-app  --workers $WORKERS --error-log $ERROR_LOG $APP_HOME/iota.psgi"
DAEMON_OPTS="--pid-file=$PIDFILE --status-file=$STATUS --port 127.0.0.1:$PORT -- $STARMAN"

. $HOME/perl5/perlbrew/etc/bashrc

cd $APP_HOME

# Here you could even do something like this to ensure deps are there:
# cpanm --installdeps .

$DAEMON --restart $DAEMON_OPTS

# If the restart failed (2 or 3) then try again. We could put in a kill.
if [ $? -gt 0 ]; then
    echo "Restart failed, application likely not running. Starting..."
    # Rely on start-stop-daemon to run start_server in the background
    # The PID will be written by start_server
    /sbin/start-stop-daemon --start --background  \
                --exec $DAEMON -- $DAEMON_OPTS
fi
