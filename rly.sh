#!/bin/bash

source consts.sh


function createClient(){
    local start_height=$1
    rly tx clients icon-archway -d --client-tp "2000000m" --icon-start-height=$start_height
}

function createConnection(){
    rly tx conn icon-archway -d

}

function createChannel(){
    rly tx chan icon-archway --src-port=mock --dst-port=mock -d
}

function handshake(){

    createConnection
    sleep 4
    createChannel


}


function establish(){ 
    cd $RLY_FOLDER
    make install

    icon_start_height=$1

    # create client function 
    createClient $1    
    sleep 2 
    handshake


}

function start(){
    echo "reinstalling relay"
    cd $RLY_FOLDER
    make install

    echo "starting relayer...."
    rly start -d
}





########## ENTRYPOINTS ###############
usage() {
    echo "Usage: $0 [CMD]"
    exit 1
}

if [ $# -ge 1 ]; then
    # Set CMD as the first argument ($1)
    CMD=$1

    # Shift the arguments to the left, discarding the first argument ($1)
    shift
else
    usage
fi


case "$CMD" in
establish )
    establish $1
    ;;
create-channel )
    createChannel
    ;;
create-connection ) 
    createConnection
    ;;
handshake ) 
    handshake
    ;;

*)
    echo "Error: unknown command: $CMD"
    usage
    ;;
esac