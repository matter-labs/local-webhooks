# ==============================================================================
# ZKsync Webhook – Local Docker Setup
# ==============================================================================

WEBHOOK_API_URL := http://localhost:8081
WEBHOOK_DESTINATION_URL ?= http://host.docker.internal:9000/webhook
DOCS_PORT ?= 3000
MDBOOK_IMAGE ?= ghcr.io/rust-lang/mdbook:latest

.DEFAULT_GOAL := help

.PHONY: help
help:
	@echo ""
	@echo "ZKsync Webhook - Local Commands"
	@echo ""
	@echo "  setup        Copy env.example → .env"
	@echo "  login        Login to Quay.io (required once)"
	@echo "  up           Start webhook + database"
	@echo "  down         Stop containers"
	@echo "  reset        Stop containers and delete data"
	@echo "  logs         Follow webhook logs"
	@echo "  status       Show container status"
	@echo "  mock-server  Run local mock webhook receiver"
	@echo "  get-token    Get tenant token via SIWE (requires ADDRESS variable)"
	@echo "  docs-serve   Serve docs site"
	@echo "  docs-build   Build static docs into ./book"
	@echo "  docs-clean   Remove built docs output"
	@echo ""

# ------------------------------------------------------------------------------
# Environment
# ------------------------------------------------------------------------------

ENV_FILE := .env

.PHONY: setup
setup:
	@if [ ! -f $(ENV_FILE) ]; then \
		cp env.example .env && echo "Created .env from env.example"; \
	else \
		echo ".env already exists"; \
	fi

.PHONY: login
login:
	@echo "Logging into Quay.io..."
	@set -a && source .env && set +a && \
	echo "$$DOCKER_PASSWORD" | docker login quay.io -u "$$DOCKER_USERNAME" --password-stdin

# ------------------------------------------------------------------------------
# Docker Compose
# ------------------------------------------------------------------------------

.PHONY: up
up:
	docker compose up -d
	@echo ""
	@echo "🚀 ZKsync Webhook is starting"
	@echo ""
	@echo "Webhook destination URL:"
	@echo "  $(WEBHOOK_DESTINATION_URL)"
	@echo ""
	@echo "Webhook API ($(WEBHOOK_API_URL))"
	@echo ""
	@echo "  Event webhooks"
	@echo "    POST    /v1/event-webhook"
	@echo "    GET     /v1/event-webhook"
	@echo "    GET     /v1/event-webhook/:id"
	@echo "    PATCH   /v1/event-webhook/:id"
	@echo "    DELETE  /v1/event-webhook/:id"
	@echo ""
	@echo "  Address webhooks"
	@echo "    POST    /v1/address-webhook"
	@echo "    GET     /v1/address-webhook"
	@echo "    GET     /v1/address-webhook/:id"
	@echo "    DELETE  /v1/address-webhook/:id"
	@echo "    GET     /v1/address-webhook/:id/addresses"
	@echo "    POST    /v1/address-webhook/:id/addresses"
	@echo "    DELETE  /v1/address-webhook/:id/addresses"
	@echo ""
	@echo "Next:"
	@echo "  1) (Optional) Run mock receiver: make mock-server"
	@echo "  2) (Optional) Get user auth token: make get-token ADDRESS=0xYourAddress"
	@echo ""

.PHONY: down
down:
	docker compose down

.PHONY: reset
reset:
	docker compose down -v
	@echo "🧹 All containers and data removed"

.PHONY: logs
logs:
	docker compose logs -f webhook-service

.PHONY: status
status:
	docker compose ps

# ------------------------------------------------------------------------------
# Mock Server
# ------------------------------------------------------------------------------

.PHONY: mock-server
mock-server:
	@command -v cargo >/dev/null 2>&1 || { \
		echo "cargo not found. Install Rust (https://rustup.rs) or skip mock-server."; \
		exit 1; \
	}
	@echo "Starting mock webhook receiver..."
	@cd tools/mock-server && RUST_LOG=info cargo run --quiet

# --------------------------------------
# Utility: Get Tenant Token via SIWE
# --------------------------------------

.PHONY: get-token
get-token:
	@echo "Running SIWE token flow..."
	@API_URL="$(API_URL)" DOMAIN="$(DOMAIN)" \
	ACCOUNT_NAME="$(ACCOUNT_NAME)" PRIVATE_KEY="$(PRIVATE_KEY)" ADDRESS="$(ADDRESS)" \
		scripts/get_token.sh

# ------------------------------------------------------------------------------
# Documentation
# ------------------------------------------------------------------------------

.PHONY: docs-serve
docs-serve:
	@echo "Serving docs at http://localhost:$(DOCS_PORT) ..."
	mdbook serve -n 0.0.0.0 -p $(DOCS_PORT)

.PHONY: docs-build
docs-build:
	mdbook build

.PHONY: docs-clean
docs-clean:
	rm -rf book
