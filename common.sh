#!/bin/bash

source consts.sh

function updateBTPNetworkId(){

    local res=$(goloop rpc --uri $ICON_NODE btpnetworktype 0x01)
    local hex_id=$(echo $res | jq '.openNetworkIDs | last ') 
     local id=0
     if [ !-z"$hex_id" ]; then
         local trim=${hex_id:3}
         local val=${trim%?};
         id=$((16#$val)) 
     fi
    
    id=$((id+1))
	echo "The btp-network-id is :" $id
	echo "$id" > $BTP_NETWORK_ID_FILE
}

function updateMockId(){

    local fullPortId=$(cat $CURRENT_MOCK_ID)
    IFS='-' read -ra values <<< "$fullPortId"
    id="${values[1]}"
    id=$((id+1))
    echo "The newmock is is :" mock-$id
	echo "mock-$id" > $CURRENT_MOCK_ID

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
  update-mock-id )
    updateMockId
  ;;

  * )
    echo "Error: unknown command: $CMD"
    usage
esac
