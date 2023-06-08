icon-node:
	./icon.sh run-node

archway-node:
	./archway.sh run-node

icon:
	./icon.sh setup

archway:
	./archway.sh setup

config:
	./cfg.update.sh

up:
	./common.sh update-btp-network-id

new-mock:
	./archway.sh new-mock
	./icon.sh new-mock
	
all:
	./common.sh update-btp-network-id
	./icon.sh setup
	./archway.sh setup
	./cfg.update.sh

