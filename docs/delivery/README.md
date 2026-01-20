# Webhook Delivery

The service delivers webhooks by sending HTTP POST requests to `WEBHOOK_DESTINATION_URL`
configured in your `.env`. The included mock receiver listens on `/webhook` at port 9000.

Default destination in `.env-example` is `http://host.docker.internal:9000/webhook`.
You can point `WEBHOOK_DESTINATION_URL` at any HTTP endpoint you control.
Use `make mock-server` for a simple local receiver that logs headers and body.
Any HTTP server that can accept POST requests can be used.

Delivery behavior is controlled by `config/config.prividium.docker.toml`, including retries
and backoff settings for the local stack.
Settings in that file are the local defaults for Docker Compose.

See the pages in this section for receiver handling, signature verification, and rotation.
