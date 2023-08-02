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
    port_name=$(cat $CURRENT_MOCK_ID)
    rly tx chan icon-archway --src-port=$port_name --dst-port=$port_name 
}

function handshake(){
    createConnection
    sleep 4
    createChannel

}

function link(){
    rly tx link icon-archway --src-port mock --dst-port mock --client-tp="20000m"  -d
    
}


function establish(){ 
    cd $RLY_FOLDER
    make install
    Link
}

function start(){
    echo "reinstalling relay"
    cd $RLY_FOLDER
    make install

    echo "starting relayer...."
    rly start icon-archway -d
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
link )
    link    
    ;;
start )
    start
    ;;

*)
    echo "Error: unknown command: $CMD"
    usage
    ;;
esac