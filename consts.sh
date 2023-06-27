#!/bin/bash


##---------------------------------------------------------##
##------------------------COMMON---------------------------##
##---------------------------------------------------------##
SCRIPTS_DIR=$PWD
CONTRACTS_DIR=$HOME/ibriz/ibc/IBC-Integration
CONTRACT_ADDRESSES_FOLDER=env

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

ARCHWAY_WALLET=godWallet
ARCHWAY_NETWORK=docker

ARCHWAY_NODE=https://rpc.constantine.archway.tech:443
CHAIN_ID=constantine-2
TOKEN=uconst
ARCHWAY_CONTRACT_ADDRESS=$CONTRACT_ADDRESSES_FOLDER/archway
ARCHWAY_DOCKER_PATH=$HOME/archway

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
    ;;
"testnet")
    echo "Selected constantine testnet"
    ARCHWAY_NODE=https://rpc.constantine.archway.tech:443
    CHAIN_ID=constantine-2
    TOKEN=uconst
    ;;
esac

ARCHWAY_KEY_DIR=$HOME/.relayer/keys/$CHAIN_ID

IBC_WASM=$CONTRACTS_DIR/artifacts/cw_ibc_core.wasm
LIGHT_WASM=$CONTRACTS_DIR/artifacts/cw_icon_light_client.wasm
MOCK_WASM=$CONTRACTS_DIR/artifacts/cw_xcall.wasm

# all the contract addresses
WASM_IBC_CONTRACT=./env/archway/.ibcHandler
WASM_LIGHT_CLIENT_CONTRACT=./env/archway/.lightclient
WASM_MOCK_APP_CONTRACT=./env/archway/.mockapp

log

##---------------------------------------------------------##
##------------------------ ICON ---------------------------##
##---------------------------------------------------------##
ICON=">>> ICON : "
echo "$ICON Icon Config---"
echo "Selected gochain..."
ICON_CONTRACT_ADDRESS=$CONTRACT_ADDRESSES_FOLDER/icon
JAVA=contracts/javascore
LIB=build/libs

ICON_WALLET=$HOME/keystore/godWallet.json
ICON_DOCKER_PATH=$HOME/gochain-btp

IBC_ICON=$CONTRACTS_DIR/$JAVA/ibc/$LIB/ibc-0.1.0-optimized.jar
LIGHT_ICON=$CONTRACTS_DIR/$JAVA/lightclients/tendermint/$LIB/tendermint-0.1.0-optimized.jar
MOCK_ICON=$CONTRACTS_DIR/$JAVA/xcall/$LIB/xcall-0.1.0-optimized.jar


#other
BTP_NETWORK_ID_FILE=./env/.btpNetworkId
BTP_NETWORK_ID=$(cat $BTP_NETWORK_ID_FILE)

# all the contract addresses
ICON_IBC_CONTRACT=./env/icon/.ibcHandler
ICON_LIGHT_CLIENT_CONTRACT=./env/icon/.lightclient
ICON_MOCK_APP_CONTRACT=./env/icon/.mockapp


export ICON_NODE=http://localhost:9082/api/v3/
export ICON_NODE_DEBUG=http://localhost:9082/api/v3d
export ICON_NODE_FILE=/Users/viveksharmapoudel/my_work_bench/ibriz/btp-related/gochain-btp


#common env 
CURRENT_MOCK_ID=./env/.mockId


log