# SIWE Token Helper (`scripts/get_token.sh`)

API requests to this service require authentication.  
This repository includes a helper script to obtain a tenant token via **Sign-In with Ethereum (SIWE)**.

---

## Prerequisites

The following tools must be installed and available in your `PATH`:

- `curl`
- `jq`
- `cast` (Foundry)
- `sed`

---

## Required environment

Add the following values to your `.env` file (or export them in your shell):

- `API_URL` — base URL for the service  
  _Example:_ `https://api.example.dev`
- `DOMAIN` — SIWE domain  
  _Example:_ `user-panel.example.dev`

### Load `.env` into your shell (recommended)

```bash
set -a
source .env
set +a
```

---

## Creating a Foundry account (recommended)

The **recommended way** to use this helper is with a **Foundry-managed account**.
This avoids placing raw private keys in environment variables and keeps key
material encrypted in Foundry’s keystore.

### Create a new account

```bash
cast wallet new
```

You will be prompted to:

- choose an account name (e.g. `dev`)
- optionally set a password

The private key is stored securely.

### Import an existing private key

If you already have a private key and want Foundry to manage it:

```bash
cast wallet import dev
```

You will be prompted to paste the private key and set a password.
After importing, you no longer need to export the private key in your environment.

### List available accounts

```bash
cast wallet list
```

### Verify an account address

```bash
cast wallet address --account dev
```

---

## Recommended usage (Foundry account)

Once a Foundry account exists, this is the preferred way to obtain a token.

```bash
scripts/get_token.sh --account dev
```

### Optionally pin / verify an address

You may explicitly provide an address. The script will verify it matches the signer:

```bash
scripts/get_token.sh --account dev 0xYourAddress
```

If the address does not match the signer, the script will fail with a clear error.

---

## Using Make (Foundry account)

```bash
make get-token ACCOUNT_NAME=dev
```

Optionally pin / verify an address:

```bash
make get-token ACCOUNT_NAME=dev ADDRESS=0xYourAddress
```

---

## Alternative usage (PRIVATE_KEY)

If you do not have a Foundry account available, you can sign using a raw private key.

```bash
PRIVATE_KEY=0xabc... scripts/get_token.sh
```

### Optional address verification

```bash
PRIVATE_KEY=0xabc... scripts/get_token.sh 0xYourAddress
```

The script will ensure the private key corresponds to the provided address.

---

## Using Make (PRIVATE_KEY)

```bash
make get-token PRIVATE_KEY=0xabc...
```

Optionally pin / verify an address:

```bash
make get-token PRIVATE_KEY=0xabc... ADDRESS=0xYourAddress
```

---

## Output

On success, the script prints:

```text
TOKEN: <value>
```

This will be used for authentication for the webhook service.

---

## Notes & troubleshooting

- If no signer is provided, the script will fail and explain how to proceed.
- If no address is provided, the script derives it automatically from the signer.
- If both a signer and address are provided, the script verifies they match.
- Use `--print-only` to debug server responses if token exchange fails.
