REPO:=github.com/tinkerbell/pbnj
REPO_BASE:=$(shell dirname ${REPO})
PROTOS_LOC:=v2/protos
BINARY:=pbnj
OSFLAG:= $(shell go env GOHOSTOS)
GIT_COMMIT:=$(shell git rev-parse --short HEAD)
BUILD_ARGS:=GOARCH=amd64 CGO_ENABLED=0 go build -trimpath -ldflags '-s -w -extldflags "-static"'

help:
	@grep -E '^[a-zA-Z_-]+:.*?## .*$$' $(MAKEFILE_LIST) | sort | awk 'BEGIN {FS = ":.*?## "}; {printf "\033[32m%-30s\033[0m %s\n", $$1, $$2}'

.PHONY: test
test: ## run tests
	go test -v -covermode=count ./...

.PHONY: test-ci
test-ci: ## run tests for ci and codecov
	go test -coverprofile=coverage.txt ./...

.PHONY: cover
cover: ## Run unit tests with coverage report
	go test -coverprofile=cover.out ./...
	go tool cover -func=cover.out
	rm -rf cover.out

.PHONY: lint
lint:  ## run linting
	@echo be sure golangci-lint is installed: https://golangci-lint.run/usage/install/
	golangci-lint run

.PHONY: buf-lint
buf-lint:  ## run linting
	@echo be sure buf is installed: https://buf.build/docs/installation
	buf check lint

.PHONY: darwin
darwin: ## complie for darwin
	GOOS=darwin ${BUILD_ARGS} -o bin/${BINARY}-darwin-amd64 main.go

.PHONY: linux
linux: ## complie for linux
	GOOS=linux ${BUILD_ARGS} -o bin/${BINARY}-linux-amd64 main.go

.PHONY: build
build: ## compile the binary for the native OS
ifeq (${OSFLAG},linux)
	@$(MAKE) linux
else
	@$(MAKE) darwin
endif

PHONY: run-server
run-server: ## run server locally
ifeq (, $(shell which jq))
	go run main.go server
else
	scripts/run-server.sh
endif

.PHONY: pbs
pbs: ## generate go stubs from protocol buffers
	scripts/protoc.sh
