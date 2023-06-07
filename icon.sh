#!/bin/bash

source consts.sh

function printDebugTrace() {
	local txHash=$1
	goloop debug trace --uri $ICON_NODE_DEBUG $txHash | jq -r .
}

function wait_for_it() {
	local txHash=$1
	echo "Txn Hash: "$1
	
	status=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .status)
	if [ $status == "0x1" ]; then
    	echo "Successful"
    else
    	echo $status
    	read -p "Print debug trace? [y/N]: " proceed
    	if [[ $proceed == "y" ]]; then
    		printDebugTrace $txHash
    	fi
    	exit 0
    fi
}

function openBTPNetwork() {
	echo "$ICON Opening BTP Network of type eth"

	local wallet=$1
	local name=$2
	local owner=$3
	local password=gochain

	local txHash=$(goloop rpc sendtx call \
	    --uri $ICON_NODE  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to cx0000000000000000000000000000000000000001 \
	    --method openBTPNetwork \
	    --param networkTypeName=eth \
	    --param name=$name \
	    --param owner=$owner \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
	sleep 2
	wait_for_it $txHash
}

function deployIBCHandler() {
	echo "$ICON Deploy IBCHandler"
	local wallet=$1
	local filename=$2
	local password=gochain

	if [ -z "$filename" ]; then
		filename=$IBC_ICON_CONTRACT_ADDRESS
	fi

	local txHash=$(goloop rpc sendtx deploy $IBC_ICON \
			--content_type application/java \
			--uri $ICON_NODE  \
			--nid 3 \
			--step_limit 100000000000\
			--to cx0000000000000000000000000000000000000000 \
			--key_store $wallet \
			--key_password $password | jq -r .)


	sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function deployMockApp() {
	echo "$ICON Deploy MockApp"
	local wallet=$1
	local password=gochain
	local ibcHandler=$2
	local filename=$3

	if [ -z "$filename" ]; then
		filename=$ICON_MOCK_APP_CONTRACT
	fi

	local txHash=$(goloop rpc sendtx deploy $MOCK_ICON \
			--content_type application/java \
			--uri $ICON_NODE  \
			--nid 3 \
			--step_limit 100000000000\
			--to cx0000000000000000000000000000000000000000 \
			--param _ibc=$ibcHandler \
			--param _timeoutHeight=50000000 \
			--key_store $wallet \
			--key_password $password | jq -r .)
        sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function deployLightClient() {
	echo "$ICON Deploy Tendermint Light Client"
	local wallet=$1
	local password=gochain
	local filename=$2
	local ibcHandler=$3

	if [ -z "$ICON_LIGHT_CLIENT_CONTRACT" ]; then
		filename=$ICON_LIGHT_CLIENT_CONTRACT
	fi

	local txHash=$(goloop rpc sendtx deploy $LIGHT_ICON \
			--content_type application/java \
			--uri $ICON_NODE  \
			--nid 3 \
			--step_limit 100000000000\
			--to cx0000000000000000000000000000000000000000 \
            --param ibcHandler=$ibcHandler\
			--key_store $wallet \
			--key_password $password | jq -r .)
    sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function registerClient() {
    echo "$ICON Register Tendermint Light Client"
    local wallet=$1
    local password=gochain
    local toContract=$2
    local clientAddr=$3

    local txHash=$(goloop rpc sendtx call \
	    --uri $ICON_NODE  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to $toContract\
	    --method registerClient \
	    --param clientType="07-tendermint" \
	    --param client=$clientAddr \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
    wait_for_it $txHash
}


function newMock(){

	local ibcHandler=$(cat $ICON_IBC_CONTRACT)
    local wallet=$ICON_WALLET
    local mockApp=$(cat $ICON_MOCK_APP_CONTRACT)
    local mock_id=$(cat $CURRENT_MOCK_ID)

	local port_id=mock-$mock_id

	bindPort $wallet $ibcHandler $port_id $mockApp

    sleep 2
    echo $res
    separator

}


function bindPort() {
    echo "$ICON Bind Mock app to a port"
    local wallet=$1
    local password=gochain
    local toContract=$2
    local portId=$3
    local mockAppAddr=$4

    local txHash=$(goloop rpc sendtx call \
	    --uri $ICON_NODE  \
	    --nid 3 \
	    --step_limit 1000000000\
	    --to $toContract\
	    --method bindPort \
	    --param moduleAddress=$mockAppAddr \
	    --param portId=$portId \
	    --key_store $wallet \
	    --key_password $password | jq -r .)
    sleep 2
    wait_for_it $txHash
}

########## ENTRYPOINTS ###############

usage() {
    echo "Usage: $0 []"
    exit 1
}

if [ $# -eq 1 ]; then
	# create folder if not exists
	if [ ! -d $CONTRACT_ADDRESSES_FOLDER/icon ]; then
		mkdir -p env/icon
	fi

    CMD=$1
else
    usage
fi

function setup() {
    log
    local wallet=$ICON_WALLET

    deployIBCHandler $wallet $ICON_IBC_CONTRACT
    echo "$ICON IBC Contract deployed at address:"
    local ibcHandler=$(cat $ICON_IBC_CONTRACT)
    echo $ibcHandler

    separator
    openBTPNetwork $wallet eth $ibcHandler

    separator
    deployLightClient $wallet $ICON_LIGHT_CLIENT_CONTRACT $ibcHandler
    echo "$ICON TM client deployed at address:"
    local tmClient=$(cat $ICON_LIGHT_CLIENT_CONTRACT)
    echo $tmClient   

    separator
    registerClient $wallet $ibcHandler $tmClient

    separator
    deployMockApp $wallet $ibcHandler $ICON_MOCK_APP_CONTRACT
    echo "$ICON Mock app deployed at address:"
    local mockApp=$(cat $ICON_MOCK_APP_CONTRACT)
    echo $mockApp

    separator
    local portId=mock
    bindPort $wallet $ibcHandler $portId $mockApp
    log
}


function callMockContract(){
	local addr=$(cat $ICON_MOCK_APP_CONTRACT)

	local txhash=$(goloop rpc sendtx call \
    			--uri http://localhost:9082/api/v3  \
    			--nid 3 \
    			--step_limit 1000000000\
    			--to $addr \
    			--method sendCallMessage \
    			--param _to=eth \
    			--param _data=0x6e696c696e \
    			--key_store $ICON_WALLET \
    			--key_password gochain | jq -r .)

    sleep 2
    wait_for_it $txHash
}


function runNode(){
	cd $ICON_NODE_FILE
	docker-compose --file=compose-single.yml up  -d
}


case "$CMD" in
  setup )
    setup
  ;;

  run-node )
	runNode
  ;;

  new-mock )
    newMock
  ;;

  test-call )
	callMockContract
	;;
  ;;
  * )
    echo "Error: unknown command: $CMD"
    usage
esac

