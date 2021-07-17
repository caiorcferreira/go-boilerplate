
VERSION ?= 0.0.1

# Image URL to use all building/pushing image targets
IMG_NAME ?= boilerplate

# Go native variables
GOOS ?= linux
GOARCH ?= amd64

help: ## Display this help.
	@awk 'BEGIN {FS = ":.*##"; printf "\nUsage:\n  make \033[36m<target>\033[0m\n"} /^[a-zA-Z_0-9-]+:.*?##/ { printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2 } /^##@/ { printf "\n\033[1m%s\033[0m\n", substr($$0, 5) } ' $(MAKEFILE_LIST)

##@ Development
run: ## Execute application locally.
	go run main.go

.PHONY: test
test: ## Run tests on project.
	go test -race -count=1 ./...

##@ Golang tools
STATICCHECK = $(shell pwd)/bin/staticcheck
staticcheck: ## Download staticcheck locally if necessary.
	$(call go-install,$(STATICCHECK),honnef.co/go/tools/cmd/staticcheck@v0.1.3)

fmt: ## Run go fmt against code.
	go fmt ./...

vet: ## Run go vet against code.
	go vet ./...

check: fmt vet staticcheck ## Execute formating, basic and advanced static analisys.
	$(STATICCHECK) ./...

##@ Build
binary := app

.PHONY: build
build: check test ## Build application binary.
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(binary) -ldflags="-s -w -extldflags -static" main.go

img := ${IMG_NAME}:${VERSION}
docker-build: ## Build docker image.
	docker build --build-arg binary_name=$(binary) -t ${img} .

docker-push: ## Push docker image.
	docker push ${img}

PROJECT_DIR := $(shell dirname $(abspath $(lastword $(MAKEFILE_LIST))))
define go-install
@[ -f $(1) ] || { \
set -e ;\
echo "Downloading $(2)" ;\
GOBIN=$(PROJECT_DIR)/bin go install $(2) ;\
}
endef