#!/bin/bash

source consts.sh

function deployContract() {

    local contactFile=$1
    local init=$2
    local contractAddr=$3
    echo "$WASM Deploying" $contactFile " and save to " $contractAddr
    

    local res=$(archwayd tx wasm store $contactFile --from $ARCHWAY_WALLET --node $ARCHWAY_NODE --chain-id $CHAIN_ID --gas-prices 0.02$TOKEN --gas auto --gas-adjustment 1.3 -y --output json -b block)
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

    local res=$(archwayd tx wasm store $contactFile --from $ARCHWAY_WALLET --node $ARCHWAY_NODE --chain-id $CHAIN_ID --gas-prices 0.02$TOKEN --gas auto --gas-adjustment 1.3 -y --output json -b block)


    local code_id=$(echo $res | jq -r '.logs[0].events[] | select(.type=="store_code") | .attributes[] | select(.key=="code_id") | .value')
    echo "code id: " $code_id


    local res=$(archwayd tx wasm migrate $contractAddr $code_id $migrate_arg \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
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

function deployMock() {
    local ibcContract=$1
    local init="{\"timeout_height\":500000,\"ibc_host\":\"{$ibcContract}\"}"

    sleep 5
    deployContract $MOCK_WASM $init $WASM_MOCK_APP_CONTRACT
    separator
    local mockApp=$(cat $WASM_MOCK_APP_CONTRACT)

    bindPortArgs="{\"bind_port\":{\"port_id\":\"mock\",\"address\":\"$mockApp\"}}"
    local res=$(archwayd tx wasm execute $ibcContract $bindPortArgs \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --gas-prices 0.02$TOKEN \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

    sleep 2
    echo $res
    separator

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
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

    sleep 2
    echo $res
    separator

}

function deployLightClient() {
    echo "To deploy light client"
    local init="{\"src_network_id\":\"0x3.icon\",\"network_id\":$BTP_NETWORK_ID,\"network_type_id\":\"1\"}"
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
        --gas-prices 0.02$TOKEN \
        --gas auto \
        --gas-adjustment 1.3 \
        -y)

    sleep 2
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

    echo "mock address" $addr

    # sendMessage="{\"send_call_message\":{\"to\":\"eth\",\"data\":\"[]\",\"rollback\":null}}"
    local sendMessage='{"send_call_message":{"to":"eth","data":[123,100,95,112,97],"rollback":null}}'
    
    echo ""
    echo ""
    
    local tx_call="archwayd tx wasm execute $addr $sendMessage \
        --from $ARCHWAY_WALLET \
        --node $ARCHWAY_NODE \
        --chain-id $CHAIN_ID \
        --gas-prices 0.02$TOKEN \
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
    deployLightClient $ibcContract
    deployMock $ibcContract

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
*)
    echo "Error: unknown command: $CMD"
    usage
    ;;
esac
