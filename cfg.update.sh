#!/bin/bash

source consts.sh
YAML_FILE=$HOME/.relayer/config/config.yaml
BACKUP_YAML_FILE=$HOME/.relayer/config/config_backup.yaml

wasmIBC=$(cat $WASM_IBC_CONTRACT)
iconIBC=$(cat $ICON_IBC_CONTRACT)
# for start height
startHeight=$(goloop rpc --uri $ICON_NODE btpnetwork $BTP_NETWORK_ID | jq -r .startHeight)
heightInt=$(printf "%d" "$startHeight")
ht=$((heightInt + 1))

echo "Current BTP Network is: " $BTP_NETWORK_ID
echo "Btp network start height is:" $ht


cp $YAML_FILE $BACKUP_YAML_FILE
rm $YAML_FILE

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
      gas-prices: 1000000000000aconst
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
      password: $ICON_WALLET_PASSWD
      icon-network-id: $ICON_SOURCE_ID
      btp-network-id: $BTP_NETWORK_ID
      btp-network-type-id: 1
      start-btp-height: 0
      ibc-handler-address: $iconIBC 
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