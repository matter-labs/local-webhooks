# Overview

This repository provides a local Docker setup for the ZKsync Webhook Service.
It is intended for short-term testing with an authenticated, private image.

The webhook delivery format adheres to the Standard Webhooks open standard.
[Specification](https://www.standardwebhooks.com/) and reference [verification libraries](https://github.com/standard-webhooks/standard-webhooks/tree/main/libraries).

What runs locally:

- Postgres and the webhook service via Docker Compose.
- Webhook deliveries sent to `WEBHOOK_DESTINATION_URL`.
- An optional mock receiver in `tools/mock-server`.

Default ports:

- API: `8081`
- Admin: `8080`

You will need Quay credentials plus `PRIVIDIUM_SIGNER_KEY` and `ENCRYPTION_KEY`
in your `.env` file before the service will start.
