#!/bin/bash

# arquivo de exemplo para iniciar o container

export SOURCE_DIR='/path/to/this-source-code'
export DATA_DIR='/path/to/persistent/data'

# confira o seu ip usando ifconfig docker0|grep 'inet addr:' 
export DOCKER_LAN_IP=172.17.0.1

# porta que será feito o bind
export LISTEN_PORT=8181

mkdir -p $DATA_DIR/redis
mkdir -p $DATA_DIR/envdir

# se vc desejar passar valores via ENV 
echo '1' > $DATA_DIR/envdir/CATALYST_DEBUG
echo '1' > $DATA_DIR/envdir/DBIC_TRACE

docker run --name NOME_SEU_CONTAINER \
	-v $SOURCE_DIR:/src -v $DATA_DIR:/data \
	-v $DATA_DIR/redis:/var/lib/redis \
	-v $DATA_DIR/envdir:/data/envdir \
 	-p $DOCKER_LAN_IP:$LISTEN_PORT:8080 \
	--cpu-shares=512 \
	--memory 1800m -d --restart unless-stopped iotaorg/iota_base
