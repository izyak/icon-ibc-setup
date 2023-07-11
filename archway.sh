#!/bin/bash
set -x
source consts.sh

function deployContract() {

    local contactFile=$1
    local init=$2
    local contractAddr=$3
    echo "$WASM Deploying" $contactFile " and save to " $contractAddr
    

    local res=$(archwayd tx wasm store $contactFile --from $ARCHWAY_WALLET --node $ARCHWAY_NODE --chain-id $CHAIN_ID --gas-prices 0.02$TOKEN --gas auto --keyring-backend test --gas-adjustment   1.3 -y --output json -b block)
    # echo "Result: "
    # echo $res

    local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    echo "code id: "
    echo $code_id

    # get contract address

    archwayd tx wasm instantiate $code_id $init \
        --from $ARCHWAY_WALLET \
        --label "name service" \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --gas auto \
        --keyring-backend test \
        --gas-prices 0.02$TOKEN \
        --gas-adjustment 1.3 \
        --admin $ARCHWAY_ADDRESS \
        -y
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

    local res=$(archwayd tx wasm store $contactFile --from $ARCHWAY_WALLET --node $ARCHWAY_NODE --chain-id $CHAIN_ID --gas-prices 0.02$TOKEN --gas auto --keyring-backend test  --gas-adjustment 1.3 -y --output json -b block)


    local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    echo "code id: " $code_id


    local res=$(archwayd tx wasm migrate $contractAddr $code_id $migrate_arg \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --keyring-backend test \
        --gas auto \
        --gas-prices 0.02$TOKEN\
        --gas-adjustment 1.3 \
        -y)

    sleep 10
    echo "this is the result" $res
    log

}

function updateIBCContract(){
    # in json encode if double code escape  
    # if single code donot escape 
    local migrate_arg="{\"clear_store\":false}"
    local ibc_address=$(cat $WASM_IBC_CONTRACT)
    
    migrateContract $IBC_WASM $ibc_address $migrate_arg
}

function updateLightContract(){

    local migrate_arg="{}"
    local light_client=$(cat $WASM_LIGHT_CLIENT_CONTRACT)
    migrateContract $LIGHT_WASM $light_client $migrate_arg
}

function updateMockContract(){
    local migrate_arg="{}"
    local mock_app=$(cat $WASM_MOCK_APP_CONTRACT)
    migrateContract $MOCK_WASM $mock_app $migrate_arg
}

function deployIBC() {
    local init='{}'
    deployContract $IBC_WASM $init $WASM_IBC_CONTRACT
}

function deployXcallModule() {

    local init="{\"network_id\":\"07-tendermint\",\"denom\":\"$TOKEN\"}"
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
    local res=$(archwayd tx wasm execute $ibcHandler $bindPortArgs \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --keyring-backend test \
        --gas-prices 0.02$TOKEN \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

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
    local initArgs="{\"configure_connection\":{\"connection_id\":\"$connId\",\"counterparty_port_id\":\"$portId\",\"counterparty_nid\":\"0x3.icon\",\"client_id\":\"${clientId}\",\"timeout_height\":10000}}"
    local xcallConnection=$(cat $WASM_XCALL_CONNECTION_CONTRACT)

    echo "$WASM Configure Connection"
    local res=$(archwayd tx wasm execute $xcallConnection $initArgs \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --keyring-backend test \
        --gas-prices 0.02$TOKEN \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

    sleep 5
    echo $res
    separator
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
    local res=$(archwayd tx wasm execute $ibcContract $bindPortArgs \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --keyring-backend test \
        --gas-prices 0.02$TOKEN \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

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
    local res=$(archwayd tx wasm execute $ibcContract $bindPortArgs \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --gas-prices 0.02$TOKEN \
        --keyring-backend test \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

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
    local res=$(archwayd tx wasm execute $ibcContract $registerClient \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --keyring-backend test \
        --gas-prices 0.02$TOKEN \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

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

    local addr=$(cat $WASM_MOCK_APP_CONTRACT)


    # sendMessage="{\"send_call_message\":{\"to\":\"eth\",\"data\":\"[]\",\"rollback\":null}}"
    local sendMessage='{"send_call_message":{"to":"eth","data":[123,100,95,112,97],"rollback":null}}'


    local op=$(archwayd query account $addr  --output json) 
    local sequence=$(echo $op | jq -r  '.account_number')
    
    echo 
    
    local tx_call="archwayd tx wasm execute $addr $sendMessage \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --gas-prices 0.02$TOKEN \
        --keyring-backend test \
        --gas auto \
        --gas-adjustment 1.3 \
        -y"
    echo "call command: " $tx_call

    local res=$($tx_call)

    sleep 2
    echo $res
    separator

}

function setup() {
    deployIBC
    local ibcContract=$(cat $WASM_IBC_CONTRACT)
    echo $ibcContract
    exit 0
    deployLightClient $ibcContract
    deployXcallModule
    # deployMock $ibcContract $WASM_MOCK_APP_CONTRACT mock

}

########## ENTRYPOINTS ###############

usage() {
    echo "Usage: $0 []"
    exit 1
}

if [ $# -eq 1 ]; then
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
update-ibc )
    updateIBCContract
    ;;
update-light )
    updateLightContract
    ;;
update-mock )
    updateMockContract
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