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
	
all:
	./common.sh update-btp-network-id
	./icon.sh setup
	./archway.sh setup
	./cfg.update.sh

ccfg:
	./icon.sh cc
	./archway.sh cc

setup-xcall:
	rly tx clients icon-archway --icon-start-height 10832322 --client-tp "10000m" --debug
	rly tx conn icon-archway -d 
# 	configureConnection in xcall connection for both chains
# 	./icon.sh cc
# 	./archway.sh cc
# 	./rly.sh create-channel
