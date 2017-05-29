#!/bin/bash

export GIT_DIR=$(git rev-parse --show-toplevel)
export MYIP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f8)

if [ -z "$MYIP" ]; then
    MYIP=$(ip route get 8.8.8.8 | head -1 | cut -d' ' -f7)
fi

echo "Make sure API is listening on $MYIP:5000 ";

(sleep 1; export X=`docker inspect --format '{{ .NetworkSettings.IPAddress }}' iota_app 2>&1`; echo "http://$X" ) &

docker run --add-host postgresql_host:$MYIP --name iota_app -v $GIT_DIR:/src -p 5000:5000  iotaorg/iota_base