# local-webhooks 
[![Standard Webhooks](https://img.shields.io/badge/Standard%20Webhooks-Compliant-brightgreen)](https://github.com/standard-webhooks/standard-webhooks)

ZKsync webhook service for local testing. Runs the webhook service and Postgres via Docker Compose, with a configurable webhook receiver target. Adheres to open standard webhooks [specification](https://github.com/standard-webhooks/standard-webhooks).

## Prerequisites

- Docker + Docker Compose
- Quay.io credentials for the private webhook image
- Optional: Rust toolchain (for `make mock-server`)
- Optional: mdbook (for `make docs-serve` / `make docs-build`)

## Documentation

Run `make docs-serve` for the full docs site, including API examples (default: `http://localhost:3000`).

## Quickstart

1) Copy the env file and fill in required values:

```sh
cp .env-example .env
```

Set:

- `DOCKER_USERNAME`, `DOCKER_PASSWORD`
- `PRIVIDIUM_SIGNER_KEY`, `ENCRYPTION_KEY`

2) Log in to Quay and start the stack:

```sh
make login
make up
```

3) (Optional) Run a local receiver:

```sh
make mock-server
```

## Endpoints

- API base: `http://localhost:8081`

Key routes:

- `POST /v1/event-webhook`
- `GET /v1/event-webhook`
- `GET /v1/event-webhook/:id`
- `PATCH /v1/event-webhook/:id`
- `DELETE /v1/event-webhook/:id`
- `POST /v1/address-webhook`
- `GET /v1/address-webhook`
- `GET /v1/address-webhook/:id`
- `DELETE /v1/address-webhook/:id`
- `GET /v1/address-webhook/:id/addresses`
- `POST /v1/address-webhook/:id/addresses`
- `DELETE /v1/address-webhook/:id/addresses`

## Configuration

- Service config: `config/config.prividium.docker.toml` (mounted read-only into the container).
- Override the config path with `HOST_CONFIG_PATH` in `.env`.
- Set your webhook receiver target with `WEBHOOK_DESTINATION_URL` (defaults to `http://host.docker.internal:9000/webhook`).

## Common commands

```sh
make up        # start services
make down      # stop services
make reset     # stop and remove data volume
make logs      # follow webhook-service logs
make status    # container status
make get-token ACCOUNT=dev
make docs-serve
make docs-build
```
