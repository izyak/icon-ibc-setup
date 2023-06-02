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
	./icon.sh setup
	./archway.sh setup
	./cfg.update.sh