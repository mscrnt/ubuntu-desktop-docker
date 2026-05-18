# Local CI mirror. Every check that runs in GitHub Actions is reproducible
# here via Docker, so the only host requirements are `make` and `docker`.

# ---- Configurable ----------------------------------------------------------
IMAGE        ?= ubuntu-desktop
TAG          ?= dev
PLATFORM     ?= linux/amd64
VARIANT      ?= full

USERNAME     ?= smoketest
PASSWORD     ?= smoketest
VNCPASSWORD  ?= smoketest

SHELLCHECK_IMG := koalaman/shellcheck:stable
HADOLINT_IMG   := hadolint/hadolint:latest
YAMLLINT_IMG   := cytopia/yamllint:latest
ACTIONLINT_IMG := rhysd/actionlint:latest

SHELL_SCRIPTS := rootfs/usr/local/bin/container-setup \
                 rootfs/usr/local/bin/healthcheck \
                 rootfs/etc/xrdp/startwm.sh \
                 tests/smoke.sh

DOCKER_RUN := docker run --rm -v "$(CURDIR)":/repo -w /repo

# Build-arg matrix per variant.
BUILD_ARGS_full := VARIANT=full INCLUDE_BROWSER=true  INCLUDE_MEDIA=true  INCLUDE_VSCODE=true  INCLUDE_DEVTOOLS=true
BUILD_ARGS_slim := VARIANT=slim INCLUDE_BROWSER=false INCLUDE_MEDIA=false INCLUDE_VSCODE=false INCLUDE_DEVTOOLS=true

# ---- Targets ---------------------------------------------------------------
.DEFAULT_GOAL := help
.PHONY: help lint lint-shell lint-docker lint-yaml lint-actions \
        build build-full build-slim smoke smoke-full smoke-slim \
        test test-full ci shell logs clean hooks release-as

help: ## Show this help
	@awk 'BEGIN {FS = ":.*?## "} /^[a-zA-Z0-9_.-]+:.*?## / {printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2}' $(MAKEFILE_LIST)

## --- Lint ----------------------------------------------------------------
lint: lint-shell lint-docker lint-yaml lint-actions ## Run every linter

lint-shell: ## shellcheck on all shell scripts
	@echo "==> shellcheck"
	$(DOCKER_RUN) $(SHELLCHECK_IMG) -e SC1091 $(SHELL_SCRIPTS)

lint-docker: ## hadolint on Dockerfile
	@echo "==> hadolint"
	$(DOCKER_RUN) $(HADOLINT_IMG) hadolint --config .hadolint.yaml Dockerfile

lint-yaml: ## yamllint on tracked yaml
	@echo "==> yamllint"
	docker run --rm -v "$(CURDIR)":/data $(YAMLLINT_IMG) -c .yamllint.yaml .

lint-actions: ## actionlint on .github/workflows
	@echo "==> actionlint"
	$(DOCKER_RUN) $(ACTIONLINT_IMG) -color

## --- Build ---------------------------------------------------------------
build: build-full ## Build default variant (full)

build-full: ## Build the full image variant
	@echo "==> build $(IMAGE):$(TAG) (full)"
	docker buildx build --load \
		--platform $(PLATFORM) \
		$(foreach a,$(BUILD_ARGS_full),--build-arg $(a)) \
		-t $(IMAGE):$(TAG) .

build-slim: ## Build the slim image variant
	@echo "==> build $(IMAGE):$(TAG)-slim (slim)"
	docker buildx build --load \
		--platform $(PLATFORM) \
		$(foreach a,$(BUILD_ARGS_slim),--build-arg $(a)) \
		-t $(IMAGE):$(TAG)-slim .

## --- Smoke ---------------------------------------------------------------
smoke: smoke-full ## Smoke-test the default variant

smoke-full: build-full ## Boot full image, verify healthcheck
	@IMAGE=$(IMAGE):$(TAG) ./tests/smoke.sh

smoke-slim: build-slim ## Boot slim image, verify healthcheck
	@IMAGE=$(IMAGE):$(TAG)-slim ./tests/smoke.sh

## --- Aggregates ----------------------------------------------------------
test: lint smoke-full ## Lint + build full + smoke (fast inner-loop)

test-full: lint smoke-full smoke-slim ## Lint + both variants + smoke (full CI mirror)

ci: test-full ## Alias for test-full

## --- Conveniences --------------------------------------------------------
shell: ## docker exec into the running smoke container (if any)
	@docker ps --filter "name=ubuntu-desktop-smoke" --format '{{.Names}}' | head -n1 | xargs -I{} docker exec -it {} bash

logs: ## docker logs of the running smoke container
	@docker ps --filter "name=ubuntu-desktop-smoke" --format '{{.Names}}' | head -n1 | xargs -I{} docker logs -f {}

clean: ## Remove built images and any leftover smoke containers
	@docker ps -a --filter "name=ubuntu-desktop-smoke" --format '{{.ID}}' | xargs -r docker rm -f
	@docker rmi -f $(IMAGE):$(TAG) $(IMAGE):$(TAG)-slim 2>/dev/null || true

release-as: ## Force release-please to cut a specific version. Usage: make release-as VERSION=1.2.3
	@test -n "$(VERSION)" || (echo "VERSION=X.Y.Z required (e.g. make release-as VERSION=1.0.0)" && exit 1)
	@git commit --allow-empty \
		-m "chore: release $(VERSION)" \
		-m "Release-As: $(VERSION)"
	@echo "Empty commit created. Push to main and the next release-please run will cut $(VERSION)."

hooks: ## Install git pre-push hook that runs `make lint`
	@printf '#!/bin/sh\nexec make -s lint\n' > .git/hooks/pre-push
	@chmod +x .git/hooks/pre-push
	@echo "Installed .git/hooks/pre-push -> make lint"
