#!/bin/bash

source consts.sh



fee_price=$(archwayd q rewards estimate-fees 1 --node $ARCHWAY_NODE --output json | jq -r '.gas_unit_price | (.amount + .denom)')
tx_call_args="--from $ARCHWAY_WALLET  --node $ARCHWAY_NODE --chain-id $CHAIN_ID $ARCHWAY_NETWORK_EXTRA --gas-prices $fee_price  --gas auto --gas-adjustment 1.3   "

function deployContract() {

    local contactFile=$1
    local init=$2
    local contractAddr=$3
    echo "$WASM Deploying" $contactFile " and save to " $contractAddr

    local res=$(archwayd tx wasm store $contactFile $tx_call_args   -y --output json -b block)

    echo $res
    sleep 10

    local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    echo "code id: "
    echo $code_id

    local addr=$(archwayd keys show godWallet --keyring-backend=test --output=json | jq -r .address)

    archwayd tx wasm instantiate $code_id $init $tx_call_args --label "archway-contract" --admin $addr -y
    log

    echo "sleep for 10 seconds"
    log
    sleep 10

    CONTRACT=$(archwayd query wasm list-contract-by-code $code_id --node $ARCHWAY_NODE --output json | jq -r '.contracts[-1]')
    echo "$WASM IBC Contract Deployed at address"
    echo $CONTRACT
    echo $CONTRACT >$contractAddr
}


function migrateContract() {

    local contactFile=$1
    local contractAddr=$2
    local migrate_arg=$3

    echo "$WASM Migrating" $contactFile "to " $contractAddr " with args " $migrate_arg

    local res=$(archwayd tx wasm store $contactFile $tx_call_args -y --output json -b block)


    local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    echo "code id: " $code_id


    local res=$(archwayd tx wasm migrate $contractAddr $code_id $migrate_arg $tx_call_args -y)

    sleep 10
    echo "this is the result" $res
    log

}

function deployXcallModule() {

    local init="{\"network_id\":\"$ARCHWAY_DEFAULT_NID\",\"denom\":\"$TOKEN\"}"
    deployContract $XCALL_MULTI_WASM $init $WASM_XCALL_MULTI_CONTRACT

    separator

    local xcallContract=$(cat $WASM_XCALL_MULTI_CONTRACT)
    local ibcHandler=$(cat $WASM_IBC_CONTRACT)
    local portId=$(cat $CURRENT_MOCK_ID)


    init="{\"ibc_host\":\"$ibcHandler\",\"port_id\":\"$portId\",\"xcall_address\":\"$xcallContract\",\"denom\":\"$TOKEN\"}"
    deployContract $XCALL_CONNECTION_WASM $init $WASM_XCALL_CONNECTION_CONTRACT

    separator

    # bind port with xcall connection
    local xcallConnection=$(cat $WASM_XCALL_CONNECTION_CONTRACT)
    bindPortArgs="{\"bind_port\":{\"port_id\":\"$portId\",\"address\":\"$xcallConnection\"}}"

    echo $WASM "Bind Port "
    local res=$(archwayd tx wasm execute $ibcHandler $bindPortArgs $tx_call_args -y)

    sleep 5
    echo $res
    separator
}

function configureConnection() {
    local srcChainId=$(yq r $RELAY_CFG 'paths.icon-archway.src.chain-id')
    local dstChainId=$(yq r $RELAY_CFG 'paths.icon-archway.dst.chain-id')
    local clientId=""
    local connId=""
    if [[ $srcChainId = "localnet" ]]; then
        clientId=$(yq r $RELAY_CFG 'paths.icon-archway.src.client-id')
        connId=$(yq r $RELAY_CFG 'paths.icon-archway.src.connection-id')
    elif [ $dstChainId = "localnet" ]; then
        clientId=$(yq r $RELAY_CFG 'paths.icon-archway.dst.client-id')
        connId=$(yq r $RELAY_CFG 'paths.icon-archway.dst.connection-id')
    fi

    local portId=$(cat $CURRENT_MOCK_ID)

    local initArgs="{\"configure_connection\":{\"connection_id\":\"$connId\",\"counterparty_port_id\":\"$portId\",\"counterparty_nid\":\"$ICON_DEFAULT_NID\",\"client_id\":\"${clientId}\",\"timeout_height\":10000}}"
    local xcallConnection=$(cat $WASM_XCALL_CONNECTION_CONTRACT)

    echo "$WASM Configure Connection"
    local res=$(archwayd tx wasm execute $xcallConnection $initArgs $tx_call_args -y)

    sleep 5
    echo $res
    separator

    local multiConnection=$(cat $WASM_XCALL_MULTI_CONTRACT)

    local args="{\"set_default_connection\":{\"nid\":\"$ICON_DEFAULT_NID\",\"address\":\"$xcallConnection\"}}"
    echo "set default connection args: " $args
        local res=$(archwayd tx wasm execute $multiConnection $args $tx_call_args -y)

    sleep 5
    echo $res

}

function deployMock() {
    local ibcContract=$1
    local mockApp=$2
    local portId=$3
    local init="{\"timeout_height\":500000,\"ibc_host\":\"$ibcContract\"}"

    sleep 5
    deployContract $MOCK_WASM $init $mockApp
    separator
    local mockApp=$(cat $mockApp)

    bindPortArgs="{\"bind_port\":{\"port_id\":\"$portId\",\"address\":\"$mockApp\"}}"
    local res=$(archwayd tx wasm execute $ibcContract $bindPortArgs $tx_call_args -y)

    sleep 2
    echo $res
    separator

}

function newChannel() {
    local ibcHandler=$(cat $WASM_IBC_CONTRACT)
    local fileName=$WASM_TEMP_APP_CONTRACT
    newChannelInternal $ibcHandler $fileName
}

function newChannelInternal() {
    echo "$WASM Create a new channel"
    local ibcHandler=$1
    local filename=$2

    rm $filename
    local ibcHandler=$(cat $WASM_IBC_CONTRACT)

    separator
    IFS='-' read -ra values <<< "$CURRENT_MOCK_ID"
    mock_suffix_id="${values[1]}"

    portId=mock-$(cat $CURRENT_MOCK_ID)
    echo "$WASM Port Id:  " $portId

    deployMock $ibcHandler $filename $portId

    # local mockXCall=$(cat $filename)

    # bindPort $wallet $ibcHandler $portId $mockXCall
}


function newMock(){

    local mockApp=$(cat $WASM_MOCK_APP_CONTRACT)
    mockID=mock-$(cat $CURRENT_MOCK_ID)

    local ibcContract=$(cat $WASM_IBC_CONTRACT)

    bindPortArgs="{\"bind_port\":{\"port_id\":\"$mockID\",\"address\":\"$mockApp\"}}"
    local res=$(archwayd tx wasm execute $ibcContract $bindPortArgs $tx_call_args -y)

    sleep 2
    echo $res
    separator

}

function deployLightClient() {
    echo "To deploy light client"
    local init="{}"
    deployContract $LIGHT_WASM $init $WASM_LIGHT_CLIENT_CONTRACT

    local lightClientAddress=$(cat $WASM_LIGHT_CLIENT_CONTRACT)
    local ibcContract=$1
    separator

    echo "$WASM Register iconclient to IBC Contract"

    registerClient="{\"register_client\":{\"client_type\":\"iconclient\",\"client_address\":\"$lightClientAddress\"}}"
    local res=$(archwayd tx wasm execute $ibcContract $registerClient $tx_call_args -y)

    sleep 5
    echo $res
    separator

}

function buildContracts() {
    cd $CONTRACTS_DIR
    ./optimize_build.sh
    cp -r $CONTRACTS_DIR/artifacts/cw_ibc_core.wasm $SCRIPTS_DIR/artifacts
    # cp -r $CONTRACTS_DIR/artifacts/cw_ibc_core.wasm  $SCRIPTS_DIR/artifacts
    cp -r $CONTRACTS_DIR/artifacts/cw_icon_light_client.wasm $SCRIPTS_DIR/artifacts
}

function callMockContract(){

    local addr=$(cat $WASM_XCALL_MULTI_CONTRACT)

    local xcall_connection_archway=$(cat $WASM_XCALL_CONNECTION_CONTRACT)
    local xcall_connection_icon=$(cat $ICON_XCALL_CONNECTION)

    local default_address="cx284306db853ba518220b7e553a710ddb12575605"
    # \"sources\":[\"$xcall_connection_archway\"],\"destinations\":[\"$xcall_connection_icon\"]
    local sendMessage="{\"send_call_message\":{\"to\":\"$ICON_DEFAULT_NID/$default_address\",\"data\":[123,100,95,112,97]}}"


    local op=$(archwayd query account $addr  --output json) 
    local sequence=$(echo $op | jq -r  '.account_number')
    
    
    local tx_call="archwayd tx wasm execute $addr $sendMessage $tx_call_args -y"
    echo "call command: " $tx_call

    local res=$($tx_call)

    sleep 2
    echo $res
    separator

}


function updateContract() {
    local contract_type=$1
    echo  $WASM "updating: " $1
    separator

    local params="{}"

    case $contract_type in 

        ibc )
            params="{\"clear_store\":false}"
            migrateContract $IBC_WASM $(cat $WASM_IBC_CONTRACT) $params
        ;;

        light )
            migrateContract $LIGHT_WASM $(cat $WASM_LIGHT_CLIENT_CONTRACT) $params
        ;;

        mock )
            migrateContract $MOCK_WASM $(cat $WASM_MOCK_APP_CONTRACT) $params
        ;;

        xcall-connection ) 
            migrateContract $XCALL_CONNECTION_WASM $(cat $WASM_XCALL_CONNECTION_CONTRACT) $params
        ;;

        xcall-multi )
            migrateContract $XCALL_MULTI_WASM $(cat $WASM_XCALL_MULTI_CONTRACT) $params
        ;;

        * )
            echo "Error: unknown contract:" $contract_type
        ;;
esac

}

function setup() {
    deployIBC
    local ibcContract=$(cat $WASM_IBC_CONTRACT)
    deployLightClient $ibcContract
    deployXcallModule
    # deployMock $ibcContract $WASM_MOCK_APP_CONTRACT mock

}

########## ENTRYPOINTS ###############

usage() {
    echo "Usage: $0 []"
    exit 1
}

if [ $# -gt 0 ]; then
    # create folder if not exists
    if [ ! -d $CONTRACT_ADDRESSES_FOLDER/archway ]; then
        mkdir -p env/archway
    fi

    CMD=$1
else
    usage
fi

case "$CMD" in
setup)
    setup
    ;;
run-node )
	runNode
    ;;
new-mock )
    newMock
    ;;
update )
    updateContract $2
    ;;
test-call ) 
    callMockContract
    ;;
chan )
    newChannel
    ;;
cc )
    configureConnection
    ;;
*)
    echo "Error: unknown command: $CMD"
    usage
    ;;
esac