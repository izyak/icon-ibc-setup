#!/bin/bash

source consts.sh


tx_call_args_icon_common=" --uri $ICON_NODE  --nid $ICON_SOURCE_ID  --step_limit 100000000000 --key_store $ICON_WALLET --key_password P@ssw0rd "

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
	    --to cx0000000000000000000000000000000000000001 \
	    --method openBTPNetwork \
	    --param networkTypeName=eth \
	    --param name=$name \
	    --param owner=$owner \
		$tx_call_args_icon_common | jq -r .)
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
			--to cx0000000000000000000000000000000000000000 \
			$tx_call_args_icon_common | jq -r .)


	sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function deployXcallMulti() {
	echo "$ICON Deploy XCall Multi Protocol"
	local wallet=$1
	local filename=$2
	local password=gochain

	local txHash=$(goloop rpc sendtx deploy $XCALL_MULTI_ICON \
			--content_type application/java \
			--to cx0000000000000000000000000000000000000000 \
			--param networkId=$ICON_DEFAULT_NID \
			$tx_call_args_icon_common | jq -r .)


	sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function deployXcallConnection() {
	echo "$ICON Deploy XCall Connection"
	local wallet=$1
	local filename=$2
	local password=gochain

    local ibcHandler=$(cat $ICON_IBC_CONTRACT)
    local xCallMulti=$(cat $ICON_XCALL_MULTI)
    local portId=$(cat $CURRENT_MOCK_ID)


	local txHash=$(goloop rpc sendtx deploy $XCALL_CONNECTION_ICON \
			--content_type application/java \
			--to cx0000000000000000000000000000000000000000 \
			--param _xCall=$xCallMulti \
			--param _ibc=$ibcHandler \
			--param port=$portId \
			$tx_call_args_icon_common| jq -r .)


	sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}


function deployXcallModule() {
	local wallet=$1
	deployXcallMulti $wallet $ICON_XCALL_MULTI
	separator
	deployXcallConnection $wallet $ICON_XCALL_CONNECTION
	separator

	local xcallConnection=$(cat $ICON_XCALL_CONNECTION)
	local ibcHandler=$(cat $ICON_IBC_CONTRACT)
	local portId=$(cat $CURRENT_MOCK_ID)

	bindPort $wallet $ibcHandler $portId $xcallConnection
}

function configureConnection() {
	local srcChainId=ibc-icon
    local dstChainId=constantine-3
    local clientId="07-tendermint-2"
    local connId="connection-6"
    # if [ $srcChainId = "ibc-icon" ]; then
    #     clientId="07-tendermint-2"
    #     connId=connection-0
    # elif [ $dstChainId = "ibc-icon" ]; then
    #     clientId=iconclient-0
    #     connId=connection-0
    # fi

	local portId=$(cat $CURRENT_MOCK_ID)
	local xcallConnection=$(cat $ICON_XCALL_CONNECTION)

    echo "$ICON Configure Connection"

    echo "$ICON Register Tendermint Light Client"
    local wallet=$ICON_WALLET
    local password=P@ssw0rd
    local toContract=$(cat $ICON_XCALL_CONNECTION)

    local txHash=$(goloop rpc sendtx call \
	    --to $toContract\
	    --method configureConnection \
	    --param connectionId=$connId \
	    --param counterpartyPortId=$portId \
	    --param counterpartyNid=$ARCHWAY_DEFAULT_NID \
	    --param clientId=$clientId \
	    --param timeoutHeight=1000000\
		$tx_call_args_icon_common | jq -r .)
    sleep 2
    wait_for_it $txHash

    separator


    # local toContract=$(cat $ICON_XCALL_MULTI)
    # echo "$ICON Set xcall connection address on xcall multiprotocol"
    # local txHash=$(goloop rpc sendtx call \
	#     --to $toContract\
	#     --method setDefaultConnection \
	#     --param nid=$ARCHWAY_DEFAULT_NID \
	#     --param connection=$xcallConnection \
	# 	$tx_call_args_icon_common | jq -r .)
    # sleep 6
    # wait_for_it $txHash

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
			--to cx0000000000000000000000000000000000000000 \
			--param _ibc=$ibcHandler \
			--param _timeoutHeight=50000000 \
			$tx_call_args_icon_common| jq -r .)

    sleep 2
	wait_for_it $txHash
	scoreAddr=$(goloop rpc txresult --uri $ICON_NODE $txHash | jq -r .scoreAddress)
	echo $scoreAddr > $filename
}

function newChannel() {
	local wallet=$ICON_WALLET
	local ibcHandler=$(cat $ICON_IBC_CONTRACT)
	local fileName=$ICON_TEMP_APP_CONTRACT
	newChannelInternal $wallet $ibcHandler $fileName

}
function newChannelInternal() {
	echo "$ICON Create a new channel"
	local wallet=$1
	local password=gochain
	local ibcHandler=$2
	local filename=$3

	rm $filename
	local ibcHandler=$(cat $ICON_IBC_CONTRACT)

	deployMockApp $wallet $ibcHandler $filename

	separator
	local portId=mock-$(cat $CURRENT_MOCK_ID)
    echo "$ICON Port Id:  " $portId

    local mockXCall=$(cat $filename)

    bindPort $wallet $ibcHandler $portId $mockXCall
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
			--to cx0000000000000000000000000000000000000000 \
            --param ibcHandler=$ibcHandler\
			$tx_call_args_icon_common| jq -r .)
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
	    --to $toContract\
	    --method registerClient \
	    --param clientType="07-tendermint" \
	    --param client=$clientAddr \
		$tx_call_args_icon_common | jq -r .)
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
    echo "$ICON Bind module to a port"
    local wallet=$1
    local password=gochain
    local toContract=$2
    local portId=$3
    local mockAppAddr=$4

    local txHash=$(goloop rpc sendtx call \
	    --to $toContract\
	    --method bindPort \
	    --param moduleAddress=$mockAppAddr \
	    --param portId=$portId \
		$tx_call_args_icon_common | jq -r .)
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
    deployXcallModule $wallet
    log
}


function callMockContract(){
	local addr=$(cat $ICON_XCALL_MULTI)

	local default_address=archway1m0zv2tl9cq6hf5tcws7j9xgyn070pz8urv06ae
	local txHash=$(goloop rpc sendtx call \
    			--to $addr \
    			--method sendCallMessage \
    			--param _to=$ARCHWAY_DEFAULT_NID/$default_address \
    			--param _data=0x6e696c696e \
				$tx_call_args_icon_common | jq -r .)

	echo $txHash
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
  cc )
    configureConnection
    ;;
  chan )
	newChannel
	;;
  * )
    echo "Error: unknown command: $CMD"
    usage
esac

