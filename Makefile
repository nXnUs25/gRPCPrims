BIN_DIR = bin
PROTO_DIR = proto
SERVER_DIR = server
CLIENT_DIR = client

SHELL := bash
SHELL_VERSION = $(shell echo $$BASH_VERSION)
UNAME := $(shell uname -s)
VERSION_AND_ARCH = $(shell uname -rm)
ifeq ($(UNAME),Darwin)
	OS = macos $(VERSION_AND_ARCH)
else ifeq ($(UNAME),Linux)
	OS = linux $(VERSION_AND_ARCH)
else
	$(error "Unsupported OS")
endif

PACKAGE = $(shell head -1 go.mod | awk '{print $$2}')
CHECK_DIR_CMD = test -d $@ || (echo "Directory $@ does not exist" && false)
HELP_CMD = grep -E '^[a-zA-Z_-]+:.*?\#\# .*$$' $(MAKEFILE_LIST) | awk 'BEGIN {FS = ":.*?\#\# "}; {printf "\033[36m%-30s\033[0m %s\n", $$1, $$2}'
SERVER_BIN = ${SERVER_DIR}
CLIENT_BIN = $(CLIENT_DIR)

.DEFAULT_GOAL := help
.PHONY: math help
project := core math

all: $(project) ## Generate Pbs and builds
math: $@ ## Generate Pbs and building client server binaries
core: $@ ## Compiele core logic 

#protoc --go_out=. --go_opt=paths=source_relative --go-grpc_out=. --go-grpc_opt=paths=source_relative proto/*.proto
$(project): ## info
	@${CHECK_DIR_CMD}
	protoc -I$@/${PROTO_DIR} --go_opt=module=${PACKAGE} --go_out=. --go-grpc_opt=module=${PACKAGE} --go-grpc_out=. $@/${PROTO_DIR}/*.proto
	go build -o $(BIN_DIR)/$@/${SERVER_BIN} ./$@/${SERVER_DIR}
	go build -o $(BIN_DIR)/$@/${CLIENT_BIN} ./$@/${CLIENT_DIR} 

test: all ## Test all 
	go test ./...

clean: clean_pbs ## clean all generated resources
	rm -rfv ${BIN_DIR}

clean_pbs: ## clean pbs generated files
	rm -fv math/${PROTO_DIR}/*.pb.go

rebuild: clean all ## rebuild whole project .. clean and then build all

pbs: ## Generate Pbs
	protoc -Imath/${PROTO_DIR} --go_opt=module=${PACKAGE} --go_out=. --go-grpc_opt=module=${PACKAGE} --go-grpc_out=. math/${PROTO_DIR}/*.proto 


about: ## Display ingo related to the platform Go version and OS
	@echo "OS: ${OS}"
	@echo "Shell: ${SHELL} ${SHELL_VERSION}"
	@echo "Protoc version: $(shell protoc --version)"
	@echo "Go version: $(shell go version)"
	@echo "Go package: ${PACKAGE}"
	@echo "Openssl version: $(shell openssl version)"

help: ## show this help message
	@${HELP_CMD}