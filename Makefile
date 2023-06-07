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

new-mock:
	./archway.sh new-mock
	./icon.sh new-mock
	
all:
# if want to re-establish send arg "update" ->  make all ARG1="update"
	./common.sh update-btp-network-id $(ARG1)
	./icon.sh setup
	./archway.sh setup
	./cfg.update.sh