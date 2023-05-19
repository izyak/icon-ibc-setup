# ICON IBC Setup Scripts

This repo is used to generate configuration files for ibc-connection between icon and archway chains.

Change `consts.sh` as per your requirements. It contains all the configuration constants.

## ICON

The submodule to be used for running ICON chain.

```sh
git clone https://github.com/izyak/gochain-btp
cd gochain-btp
make ibc-ready
```

## ARCHWAY

Options for Archway Node: 
1. Binary with 2 validators

```sh
https://github.com/izyak/archway-node
cd archway-node
./node1.sh
```
on another terminal
```sh
cd archway-node
./node2.sh
```

2. DockerFile
```sh
https://github.com/archway-network/archway/
docker build -t archwaynetwork/archwayd:latest .
```

3. Use constantine testnet
As of now, constantine-2 is active. This should be replaced by constantine-3 when constantine-2 is deprecated.

## RUN
```sh
make all
```