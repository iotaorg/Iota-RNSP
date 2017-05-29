#!/bin/sh
perl -pi -w -e 's/daemonize yes/daemonize no/g;' /etc/redis/redis.conf
exec /sbin/setuser redis redis-server  /etc/redis/redis.conf
