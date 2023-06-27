#!/bin/bash

source consts.sh

function deployContract() {

    local contactFile=$1
    local init=$2
    local contractAddr=$3
    echo "$WASM Deploying" $contactFile " and save to " $contractAddr
    

    local res=$(archwayd tx wasm store $contactFile --from $ARCHWAY_WALLET --node $ARCHWAY_NODE --keyring-backend test --chain-id $CHAIN_ID --gas-prices 0.02$TOKEN --gas auto --gas-adjustment 1.3 -y --output json -b block)
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
        -y --no-admin
    log

    echo "sleep for 10 seconds"
    log
    sleep 10

    CONTRACT=$(archwayd query wasm list-contract-by-code $code_id --node $ARCHWAY_NODE --output json | jq -r '.contracts[-1]')
    echo "$WASM IBC Contract Deployed at address"
    echo $CONTRACT
    echo $CONTRACT >$contractAddr
}

function deployIBC() {
    local init='{}'
    deployContract $IBC_WASM $init $WASM_IBC_CONTRACT
}

function deployMock() {
    local ibcContract=$1
    local init="{\"timeout_height\":500000,\"ibc_host\":\"{$ibcContract}\"}"

    deployContract $MOCK_WASM $init $WASM_MOCK_APP_CONTRACT
    separator
    local mockApp=$(cat $WASM_MOCK_APP_CONTRACT)

    local bindPortArgs="{\"bind_port\":{\"port_id\":\"mock\",\"address\":\"$mockApp\"}}"
    local res =$(archwayd tx wasm execute $ibcContract $bindPortArgs \
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
        --gas-prices 0.02$TOKEN \
        --keyring-backend test \
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
*)
    echo "Error: unknown command: $CMD"
    usage
    ;;
esac
