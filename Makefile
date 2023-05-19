icon:
	./icon.sh setup

archway:
	./archway.sh setup

config:
	./cfg.update.sh

all:
	./icon.sh setup
	./archway.sh setup
	./cfg.update.sh