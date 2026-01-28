# Prividium Service Account

The webhook service authenticates to Prividium using a **service account**.
You will reference the service account’s private key as `PRIVIDIUM_SIGNER_KEY`
in your local `.env`.

**Note:** This is only required for local use of the Webhooks service.

---

## 1. Create an Ethereum account

Create a new Ethereum account and securely store:

- Public address
- Private key (required later)

---

## 2. Register the service account in Prividium

1. Log in to the Prividium Admin Dashboard

**Note:** Update to reflect your environment.

   ```bash
   https://admin.testnet.zksync.dev/
   ```

2. Navigate to **Services**
3. Click **+ New Service**
4. Fill in:
   - **Name**: Descriptive service name (e.g. `local-webhooks`)
   - **Public Key**: Ethereum address created above
5. Click **Save**

You should now see the service listed in the Services table.

> You will reference this account’s private key in your local `.env` file.
