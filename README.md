# ICON IBC Setup Scripts

This repo is used to generate configuration files for ibc-connection between icon and archway chains.

## ICON

The submodule to be used for running ICON chain.

```sh
https://github.com/izyak/gochain-btp
make ibc-ready
```

## ARCHWAY

Options for Archway Node: 
1. Binary with 2 validators

```
https://github.com/izyak/archway-node
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