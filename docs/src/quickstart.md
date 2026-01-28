# Quickstart

This guide walks you through running the ZKsync Webhook service locally using
Docker, and validating end-to-end webhook delivery.

---

## 1. Set up environment

Create a local `.env` file:

```bash
make setup
````

Edit `.env` and set the required values.

### Required

- `DOCKER_USERNAME` — Quay.io username
- `DOCKER_PASSWORD` — Quay.io password or access token
- `PRIVIDIUM_SIGNER_KEY` — signer key used by the service (**local only**)
- `ENCRYPTION_KEY` — encryption key used for stored secrets (**local only**)
- `WEBHOOK_DESTINATION_URL` — URL where webhooks will be delivered

Example for local testing:

```env
WEBHOOK_DESTINATION_URL=http://host.docker.internal:9000/webhook
```

> **Note**
> `PRIVIDIUM_SIGNER_KEY` and `ENCRYPTION_KEY` are only required for local
> development. In managed deployments, these are handled by ZKsync.

### Create a Prividium service account (local use only)

The webhook service authenticates to Prividium using a **service account**.
You will use its private key as `PRIVIDIUM_SIGNER_KEY` in your `.env`.

1. Create a new Ethereum account and securely store the public address and private key.
2. Register the service account in the Prividium Admin Dashboard:
   - Log in:

     **Note:** Update to reflect your own environment.

     ```bash
     https://admin.testnet.zksync.dev/
     ```

   - Navigate to **Services**
   - Click **+ New Service**
   - Fill in:
     - **Name**: Descriptive service name (e.g. `local-webhooks`)
     - **Public Key**: The Ethereum address created above
   - Click **Save**

You should now see the service listed in the Services table.

---

## 2. Log in to Quay.io

Docker images are pulled from Quay and require authentication. Recall these credentials will be provided to you by Matter Labs.

```bash
make login
```

---

## 3. Start the stack

Start the webhook service and database:

```bash
make up
```

By default:

- API base URL: `http://localhost:8081`
- If you only need a different host port, set `API_PORT` in `.env`
- If you need the service to listen on a different port, update the config file
  and Docker Compose (see [Configuration](./configuration.md))

The startup output lists available API endpoints.

To view the service logs, run:

```bash
make logs
```

---

## 4. (Optional) Run a local mock receiver

For local testing, you can run a simple webhook receiver that prints headers and
payloads.

```bash
make mock-server
```

This starts a local Rust-based server that logs incoming webhook deliveries.
It is useful for inspecting payloads and signature headers.

---

## 5. (Optional) Get a SIWE auth token

API endpoints for Prividium chains require authentication. This repo includes a helper that obtains a token via **Sign-In with Ethereum (SIWE)**.

### 5.1 Configure SIWE auth context (local only)

Ensure the following exist in your `.env`:

**Note:** Update values to reflect correct API_URL and domain.

```
API_URL=https://api.testnet.zksync.dev
DOMAIN=user-panel.testnet.zksync.dev
```

> These values are only used by helper scripts, not by the running service.

### 5.2 Generate a token (Foundry keystore recommended)

Make sure a Foundry account exists in your keystore (see the **SIWE Token Helper**
page for how to create or import an account).

**Note:** Update `ACCOUNT` to reflect own Foundry keystore name.

```bash
make get-token ACCOUNT=test-account
```

On success, the token is printed to stdout:

```text
TOKEN: <value>
```

Treat this token as a credential.

Export the returned token for convenience:

```bash
export TOKEN=<PASTE_TOKEN_HERE>
```

### 5.3 Alternative (raw private key)

If you don’t have a Foundry account, you can run the script directly:

```bash
PRIVATE_KEY=0xabc... scripts/get_token.sh
```

Optional address verification:

```bash
PRIVATE_KEY=0xabc... ADDRESS=0xYourAddress scripts/get_token.sh
```

---

## 6. Create an event webhook (example)

With the service running and a token available, you can create a webhook
subscription for on-chain events.

This example creates an **event webhook** that delivers matching logs to your
configured `WEBHOOK_DESTINATION_URL`.

```bash
curl -X POST "$API_URL/v1/event-webhook" \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer $TOKEN" \
  -d '{
    "name": "example-event-webhook",
    "url": "http://host.docker.internal:9000/webhook",
    "contract": "0x66EC845C0B07D1728B1b14921D561fe7963A5Ab8",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b"
  }'
```

On success, the API returns the created webhook configuration, including its `id`.

When matching events are detected on-chain, webhook deliveries will be sent to:

```text
WEBHOOK_DESTINATION_URL
```

If you are running the mock receiver, you should see:

- request headers (including `webhook-signature`)
- the full JSON payload printed

### Troubleshooting delivery

If you don’t see deliveries:

- ensure the webhook is `enabled: true`
- verify the destination URL is reachable from Docker
- inspect logs:

```bash
make logs
```

---

## 7. Stop the stack

To stop all containers:

```bash
make down
```

To stop containers **and remove all local data**:

```bash
make reset
```

---

## Useful commands

Run `make help` to see all available local commands:

```bash
make help
```

This includes:

- container status and logs
- mock webhook receiver
- SIWE token helper
- documentation serving and build commands

---

## What’s next

Once the stack is running and you’ve seen a webhook delivered, you can:

- create additional event or address webhooks
- verify webhook signatures
