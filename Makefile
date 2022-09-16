# Application version
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
	go run cmd/app/main.go

.PHONY: test
test: ## Run tests on project.
	go test --tags=e2e -race -count=1 ./...

.PHONY: test/unit
test/unit: ## Run unit tests on project.
	@echo "Running unit tests"
	@if [ ! -z "$(CI_JOB_ID)" ]; then go test -run . ./... -race -count=1 -coverprofile coverage.out -json > go-test-report.json; else go test -race -count=1 -cover ./...; fi;

.PHONY: test/e2e
test/e2e: ## Run e2e tests on project.
	go test --tags=e2e -count=1 ./e2e/...

tag: ## Create git tag based on application version.
	git tag -a -m "v$(VERSION)" v$(VERSION)

gen: ## Run code generation.
	go generate ./...

##@ Golang tools

.PHONY: lint
lint: ## Generate sonar report if running on ci
	@echo "Linting with golangci-lint"	
	@if [ ! -z "$(CI_JOB_ID)" ]; then \
		golangci-lint run -c .golangci.yml --out-format code-climate:gl-code-quality-report.json,colored-line-number,checkstyle:golangci-report.xml --sort-results; \
	else \
		$(MAKE) golangcilint; \
		$(GOLANGLINT) run -c .golangci.yml; \
	fi;

GOLANGLINT = $(shell pwd)/bin/golangci-lint
golangcilint: ## Download golangci-lint locally if necessary.
	$(call go-install,$(GOLANGLINT),github.com/golangci/golangci-lint/cmd/golangci-lint@v1.46.2)

##@ Build
binary := app

.PHONY: build
build: ## Build application binary.
	CGO_ENABLED=0 GOOS=$(GOOS) GOARCH=$(GOARCH) go build -o $(binary) -ldflags="-s -w -extldflags -static" cmd/app/main.go

img := ${IMG_NAME}:${VERSION}
docker-build: ## Build docker image.
	docker build -t ${img} .

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
