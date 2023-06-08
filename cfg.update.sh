#!/bin/bash

source consts.sh
YAML_FILE=$HOME/.relayer/config/config.yaml
BACKUP_YAML_FILE=$HOME/.relayer/config/config_backup.yaml

wasmIBC=$(cat $WASM_IBC_CONTRACT)
iconIBC=$(cat $ICON_IBC_CONTRACT)
# for start height
startHeight=$(goloop rpc --uri $ICON_NODE btpnetwork 0x1 | jq -r .startHeight)
heightInt=$(printf "%d" "$startHeight")
ht=$((heightInt + 1))
echo "Current BTP Network is: " $BTP_NETWORK_ID

cp $YAML_FILE $BACKUP_YAML_FILE
rm $YAML_FILE

echo "The start BTP Height is:: " $ht
cat <<EOF >> $YAML_FILE
global:
  api-listen-addr: :5183
  timeout: 10s
  memo: ""
  light-cache-size: 20
chains:
  archway:
    type: archway
    value:
      key-directory: $ARCHWAY_KEY_DIR 
      key: default
      chain-id: $CHAIN_ID
      rpc-addr: $ARCHWAY_NODE
      account-prefix: archway
      keyring-backend: test
      gas-adjustment: 1.5
      gas-prices: 0.02$TOKEN
      min-gas-amount: 1_000_000
      debug: true
      timeout: 20s
      block-timeout: ""
      output-format: json
      sign-mode: direct
      extra-codecs: []
      coin-type: 0
      broadcast-mode: batch
      ibc-handler-address: $wasmIBC
  icon:
    type: icon
    value:
      key: ""
      chain-id: ibc-icon
      rpc-addr: $ICON_NODE 
      timeout: 30s
      keystore: $ICON_WALLET 
      password: gochain
      icon-network-id: 3
      btp-network-id: $BTP_NETWORK_ID
      btp-network-type-id: 1
      start-btp-height: 0
      ibc-handler-address: $iconIBC 
      archway-handler-address: $wasmIBC
paths:
  icon-archway:
    src:
      chain-id: ibc-icon
    dst:
      chain-id: $CHAIN_ID

    src-channel-filter:
      rule: ""
      channel-list: []
EOF