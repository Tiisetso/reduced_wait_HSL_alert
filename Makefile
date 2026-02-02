PORT := /dev/cu.wchusbserial140
BAUD := 115200
UPL := nodemcu-uploader --port $(PORT) --baud $(BAUD)

FIRMWARE := firmware/nodemcu-release-14-modules-2025-07-07-14-04-28-float.bin

LUA := $(wildcard *.lua)
GQL := $(wildcard *.gql)
FILES := $(LUA) $(GQL)

.PHONY: re where upload upload-c rm-init format flash ls restart term

all: re

where:
	ls /dev/cu.* /dev/tty.* 

upload:
	@echo "Uploading .gql and .lua files"
	@echo "Uploading files: $(FILES)"
	@$(UPL) upload $(FILES)

upload-c: 
	@echo "Uploading .gql and compiled .lua"
	@$(UPL) upload $(GQL)
	@$(UPL) upload --compile $(LUA)

upload-secrets:
	@echo "Generating and uploading secrets.lua (from .env)"
	@chmod +x ./scripts/generate_secrets.sh
	@./scripts/generate_secrets.sh
	@$(UPL) upload secrets.lua
	@rm -f secrets.lua

rm-init:
	@echo "Removing init.lua"
	@$(UPL) file remove init.lua
	@$(UPL) node restart

format:
	@echo "Formatting..."
	@$(UPL) file format
	@$(UPL) file list

flash:
	@echo "Flashing firmware $(FIRMWARE) to $(PORT)"
	esptool.py --port $(PORT) write_flash -fm dio -fs 4MB 0x00000 $(FIRMWARE)

re: format upload-c

ls:
	@$(UPL) file list

restart:
	@echo "Restarting NodeMCU"
	@$(UPL) node restart

term:
	@$(UPL) terminal