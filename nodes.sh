#!/bin/bash

source consts.sh

function startNodeIcon() {
	cd $ICON_DOCKER_PATH
	# non persistent
	make ibc-ready
	# persistent
	# make start
}

function startNodeArchway() {
	cd $ARCHWAY_DOCKER_PATH
	docker compose up -d
}

function stopNodeIcon() {
	cd $ICON_DOCKER_PATH
	make stop
}

function stopNodeArchway() {
	cd $ARCHWAY_DOCKER_PATH
	docker compose down
}

function startBothNodes() {
	startNodeIcon
	startNodeArchway
}

function stopBothNodes() {
	stopNodeIcon
	stopNodeArchway
}

function usage() {
	echo "Script to run Icon and Archway Nodes"
	echo 
	echo "Usage: "
	echo "         ./nodes.sh icon-node-start                : Start BTP enabled icon local node"
	echo "         ./nodes.sh archway-node-start             : Start archway local node"
	echo "         ./nodes.sh icon-node-stop                 : Stop BTP enabled icon local node"
	echo "         ./nodes.sh archway-node-stop              : Stop archway local node"
	echo "         ./nodes.sh start-all                      : Start both local nodes"
	echo "         ./nodes.sh close-all                      : Stop both local nodes"
}

if [ $# -eq 1 ]; then
	echo "Script to run Icon and Archway Nodes"
    CMD=$1
else
    usage
fi

case "$CMD" in
  icon-node-start )
    startNodeIcon
  ;;
  archway-node-start )
    startNodeArchway
  ;;
  icon-node-stop )
    startNodeIcon
  ;;
  archway-node-stop )
    startNodeArchway
  ;;
  start-all )
    startBothNodes
  ;;
  close-all )
    stopBothNodes
  ;;
  * )
    echo "Error: unknown command: $CMD"
    usage
esac