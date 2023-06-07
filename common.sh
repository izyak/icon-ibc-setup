#!/bin/bash

source consts.sh




function updateBTPNetworkId(){

	local current_value=$(cat $BTP_NETWORK_ID_FILE)

    echo "the arg is :" $1

	if [ "$1" = "update" ]; then
        echo "inside the incrementing "
    	((current_value++))
	else
    	# Increment the value by one
        echo "inside setting to one "

	    current_value=1
	fi

	# Write the updated value back to the file
	echo "$current_value" > $BTP_NETWORK_ID_FILE

	# Display the updated value
	echo "The btp-network-id is : $current_value"
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
	updateBTPNetworkId $1
  ;;

  * )
    echo "Error: unknown command: $CMD"
    usage
esac
