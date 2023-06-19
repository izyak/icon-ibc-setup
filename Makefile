icon-node:
	./icon.sh run-node

archway-node:
	./archway.sh run-node

icon:
	./icon.sh setup

up:
	./common.sh update-btp-network-id

archway:
	./archway.sh setup

config:
	./cfg.update.sh

new-mock:
	./common.sh update-mock-id
	./archway.sh new-mock
	./icon.sh new-mock
	
all:
	./common.sh update-btp-network-id
	./icon.sh setup
	./archway.sh setup
	./cfg.update.sh

