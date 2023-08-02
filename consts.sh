#!/bin/bash


##---------------------------------------------------------##
##------------------------COMMON---------------------------##
##---------------------------------------------------------##
SCRIPTS_DIR=$PWD
CONTRACTS_DIR=$HOME/ibriz/ibc/IBC-Integration
CONTRACT_ADDRESSES_FOLDER=env
RELAY_CFG=$HOME/.relayer/config/config.yaml

function log() {
    echo "=============================================="
}

function separator() {
    echo "----------------------------------------------"
}


##---------------------------------------------------------##
##------------------------Archway--------------------------##
##---------------------------------------------------------##
WASM=">>> COSMWASM: "
log
echo "$WASM: Archway Config"

ARCHWAY_WALLET=main
# address of archway wallet address
ARCHWAY_NETWORK=docker
WASM_TEMP_APP_CONTRACT=./env/archway/.newApp

ARCHWAY_NETWORK_EXTRA=" "

ARCHWAY_NODE=https://rpc.constantine.archway.tech:443
CHAIN_ID=constantine-3
TOKEN=aconst
ARCHWAY_CONTRACT_ADDRESS=$CONTRACT_ADDRESSES_FOLDER/archway
ARCHWAY_DOCKER_PATH=$HOME/archway
ARCHWAY_GAS=0.25

case "$ARCHWAY_NETWORK" in
"localnet")
    echo "Selected localnet..."
    ARCHWAY_NODE=http://localhost:26657
    CHAIN_ID=my-chain
    TOKEN=validatortoken
    ;;
"docker")
    echo "Selected docker image..."
    ARCHWAY_NODE=http://localhost:26657
    CHAIN_ID=localnet
    TOKEN=stake
    ARCHWAY_WALLET=godWallet
    ARCHWAY_GAS=0.025
    ;;
"testnet")
    echo "Selected constantine testnet"
    ARCHWAY_NODE=https://rpc.constantine.archway.tech:443
    CHAIN_ID=constantine-3
    TOKEN=aconst
    ARCHWAY_WALLET=main
    ARCHWAY_GAS=1000000000000
    ;;
esac

ARCHWAY_KEY_DIR=$HOME/.relayer/keys/$CHAIN_ID

IBC_WASM=$CONTRACTS_DIR/artifacts/archway/cw_ibc_core.wasm
LIGHT_WASM=$CONTRACTS_DIR/artifacts/archway/cw_icon_light_client.wasm
# MOCK_WASM=$CONTRACTS_DIR/artifacts/archway/cw_xcall.wasm
XCALL_MULTI_WASM=$CONTRACTS_DIR/artifacts/archway/cw_xcall.wasm
XCALL_CONNECTION_WASM=$CONTRACTS_DIR/artifacts/archway/cw_xcall_ibc_connection.wasm
XCALL_DAPP_WASM=$CONTRACTS_DIR/artifacts/archway/cw_mock_dapp_multi.wasm


# all the contract addresses
WASM_IBC_CONTRACT=./env/archway/.ibcHandler
WASM_LIGHT_CLIENT_CONTRACT=./env/archway/.lightclient
WASM_MOCK_APP_CONTRACT=./env/archway/.mockapp
WASM_XCALL_MULTI_CONTRACT=./env/archway/.xcallMulti
WASM_XCALL_CONNECTION_CONTRACT=./env/archway/.xcallConnection
WASM_XCALL_DAPP_CONTRACT=./env/archway/.xcallDapp

log

##---------------------------------------------------------##
##------------------------ ICON ---------------------------##
##---------------------------------------------------------##
ICON=">>> ICON : "
echo "$ICON Icon Config---"
ICON_CONTRACT_ADDRESS=$CONTRACT_ADDRESSES_FOLDER/icon
JAVA=contracts/javascore
LIB=build/libs

ICON_NETWORK=goloop #goloop

case "$ICON_NETWORK" in
"berlin")
    echo "Selected Berlin Testnet..."
    export ICON_SLEEP_TIME=8
    export ICON_NID=7
    export ICON_NODE=https://berlin.net.solidwallet.io/api/v3/
    export ICON_NODE_DEBUG=https://berlin.net.solidwallet.io/api/v3d
    export ICON_DEFAULT_NID="0x7.icon"
    export ICON_WALLET=$HOME/keystore/key.json
    export ICON_PASSWORD="P@ssw0rd"
    ;;
"goloop")
    echo "Selected gochain..."
    export ICON_SLEEP_TIME=2
    export ICON_NID=3
    export ICON_NODE=http://localhost:9082/api/v3
    export ICON_NODE_DEBUG=http://localhost:9082/api/v3d
    export ICON_DEFAULT_NID="0x3.icon"
    export ICON_WALLET=$HOME/keystore/godWallet.json
    export ICON_PASSWORD="gochain"
    ;;
esac


ICON_DOCKER_PATH=$HOME/gochain-btp

IBC_ICON=$CONTRACTS_DIR/artifacts/icon/ibc-0.1.0-optimized.jar
LIGHT_ICON=$CONTRACTS_DIR/artifacts/icon/tendermint-0.1.0-optimized.jar
XCALL_MULTI_ICON=$CONTRACTS_DIR/artifacts/icon/xcall-0.1.0-optimized.jar
XCALL_CONNECTION_ICON=$CONTRACTS_DIR/artifacts/icon/xcall-connection-0.1.0-optimized.jar
MOCK_ICON=$CONTRACTS_DIR/artifacts/icon/mockapp-0.1.0-optimized.jar
XCALL_DAPP_ICON=$CONTRACTS_DIR/artifacts/icon/dapp-multi-protocol-0.1.0-optimized.jar


#other
BTP_NETWORK_ID_FILE=./env/.btpNetworkId
BTP_NETWORK_ID=$(cat $BTP_NETWORK_ID_FILE)

# all the contract addresses
ICON_IBC_CONTRACT=./env/icon/.ibcHandler
ICON_LIGHT_CLIENT_CONTRACT=./env/icon/.lightclient
ICON_MOCK_APP_CONTRACT=./env/icon/.mockapp
ICON_TEMP_APP_CONTRACT=./env/icon/.newApp
ICON_XCALL_MULTI=./env/icon/.xcallMulti
ICON_XCALL_CONNECTION=./env/icon/.xcallConnection
ICON_XCALL_DAPP_CONTRACT=./env/icon/.xcallDapp

# for gochain
export ICON_NODE_FILE=/Users/viveksharmapoudel/my_work_bench/ibriz/btp-related/gochain-btp

#common env 
export CURRENT_MOCK_ID=./env/.mockId
export ARCHWAY_DEFAULT_NID="archway"


log