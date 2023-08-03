icon-node:
	./icon.sh run-node

archway-node:
	./archway.sh run-node

nodes:
	./nodes.sh start-all

stop-nodes:
	./nodes.sh close-all

restart:
	./nodes.sh close-all
	./nodes.sh start-all

test-data:
	./prepare_test_data.sh

icon:
	./icon.sh setup

archway:
	./archway.sh setup

config:
	./cfg.update.sh

new-mock:
	./common.sh update-mock-id
	./archway.sh chan
	./icon.sh chan

chan:
	./icon.sh chan
	./archway.sh chan
	
contracts:
# 	./common.sh update-btp-network-id
	./icon.sh setup
	./archway.sh setup
	./icon.sh dapp
	./archway.sh dapp
	./cfg.update.sh

ccfg:
	./icon.sh cc
	./archway.sh cc

tempchan:
	./icon.sh tempchan

xx:
	rly tx clients icon-archway --client-tp "10000000m" # --btp-block-height 11313986
	rly tx conn icon-archway
	./icon.sh tempchan

	# configureConnection in xcall connection for both chains
	./icon.sh cc
	./archway.sh cc
	./rly.sh create-channel


