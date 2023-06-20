#!/bin/bash

source consts.sh

wasmIBC=$(cat $WASM_IBC_CONTRACT)

DATA_LOCATION=$HOME/.relayer/debug_archway_msg_data.json
SRC_CHAIN=$(yq r ~/.relayer/config/config.yaml paths.icon-archway.src.chain-id | xargs)
DST_CHAIN=$(yq r ~/.relayer/config/config.yaml paths.icon-archway.dst.chain-id | xargs)

if [[ "$SRC_CHAIN" == "$CHAIN_ID" && "$DST_CHAIN" == "ibc-icon" ]]; then 
	echo "Source: Archway  --  Destination: Icon"
	OVERWRITE_TO=$CONTRACTS_DIR/test_data/icon_to_archway_raw.json
elif [[ "$SRC_CHAIN" == "ibc-icon" && "$DST_CHAIN" == "$CHAIN_ID" ]]; then
	echo "Source: Icon  --  Destination: Archway"
	OVERWRITE_TO=$CONTRACTS_DIR/test_data/archway_to_icon_raw.json
else 
	echo "Invalid relayer config. Please check source and destionation chain id. Should be $CHAIN_ID or ibc-icon ---"
	exit 0
fi

rm $OVERWRITE_TO

data=$(cat $DATA_LOCATION | jq -r .)

cat <<EOF >> $OVERWRITE_TO
{
	"address": "$wasmIBC",
	"data": $data
}
EOF

echo $OVERWRITE_TO " updated !!!"