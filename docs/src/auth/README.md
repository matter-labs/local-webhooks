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

---

## Prividium service account (local use only)

The webhook service authenticates to Prividium using a **service account**.
You will use its private key as `PRIVIDIUM_SIGNER_KEY` in your local `.env`.

See the full setup guide:

- **Prividium Service Account** in this section

1. Create a new Ethereum account and securely store the public address and private key.
2. Register the service account in the Prividium Admin Dashboard:
   - Log in:

     **Note:** Update value to reflect your own environment.

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
