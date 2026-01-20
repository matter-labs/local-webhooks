# Authentication

Local testing requires two separate auth steps:
- Quay login to pull the private webhook-service image.
- SIWE token for authenticated API requests.

This repo provides helpers for both:
- `make login` uses the Quay credentials in `.env`.
- `make get-token` runs the SIWE flow and prints a token.

Notes:
- Quay credentials are provided by Matter Labs.
- Keep registry credentials and tokens out of source control.
- Tokens are printed to stdout; store them securely.
- Webhook deliveries use a signing key, not the API token.
