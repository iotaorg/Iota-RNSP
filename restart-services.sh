#!/bin/bash

# API 
export PIDFILE=/tmp/start_server.pid
if [ -e "$PIDFILE" ]; then
	kill -HUP $(cat $PIDFILE)
fi

# email daemon
# ps aux|grep -v grep| grep script/emails_queue_sender.pl| awk '{print $2}' | xargs kill
