#!/bin/bash

source consts.sh

function updateBTPNetworkId(){

    local res=$(goloop rpc --uri $ICON_NODE btpnetworktype 0x01)
    local hex_id=$(echo $res | jq '.openNetworkIDs | last ')    
    local id=0
    if [ !-z"$hex_id" ]; then
        local trim=${hex_id:3}
        id=${trim%?};
    fi
    
    id=$((id+1))
	echo "The btp-network-id is :" $id
	echo "$id" > $BTP_NETWORK_ID_FILE
}


########## ENTRYPOINTS ###############
usage() {
    echo "Usage: $0 [CMD]"
    exit 1
}

if [ $# -ge 1 ]; then
    # Create folder if it does not exist
    if [ ! -d $CONTRACT_ADDRESSES_FOLDER ]; then
        mkdir -p env
    fi

    # Set CMD as the first argument ($1)
    CMD=$1

    # Shift the arguments to the left, discarding the first argument ($1)
    shift
else
    usage
fi

case "$CMD" in

  update-btp-network-id )
	updateBTPNetworkId
  ;;

  * )
    echo "Error: unknown command: $CMD"
    usage
esac
