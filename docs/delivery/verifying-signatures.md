# Verifying Signatures

Each webhook delivery includes a cryptographic signature that allows you to verify
that the request:

- originated from this service
- was not modified in transit
- is recent (protected against replay attacks)

Signature verification is strongly recommended for all production receivers.

---

## Standard Webhooks headers

Each request includes these headers (case-insensitive):

- `webhook-id`
- `webhook-timestamp`
- `webhook-signature`

### Header semantics

- `webhook-id`
  - Unique per event
  - Stable across retries
  - Use for idempotency
- `webhook-timestamp`
  - Unix timestamp (seconds)
  - Used to prevent replay attacks
- `webhook-signature`
  - One or more signatures (space-delimited)
  - Supports key rotation

---

## Signing key

Each webhook endpoint is associated with a signing key (sometimes called a signing
secret).

- The key is shared only between you and the service
- It is used as the HMAC key when computing the signature
- You must store it securely (treat it like an API key)
- It is returned on webhook creation and key rotation

The signing key is not included in webhook payloads or headers.

---

## Signature format

```
webhook-signature: v1,<sig1> v1,<sig2>
```

- Each signature is `v1,<base64>` where `base64` is an HMAC-SHA256 digest
- Multiple signatures may be present during key rotation

---

## What is signed

The signing input is:

```
<webhook-id>.<webhook-timestamp>.<raw-payload>
```

Important:

- The payload must be verified exactly as received
- Do not parse and re-serialize JSON before verification

Even minor formatting changes will invalidate signatures.

---

## Verification steps (production)

1. Read the raw request body bytes
2. Extract:
   - `webhook-id`
   - `webhook-timestamp`
   - `webhook-signature`
3. Parse the timestamp and enforce a tolerance window (recommend +/- 5 minutes)
4. For each active signing key, compute the `v1` signature over the signing input
5. Compare signatures using constant-time comparison
6. Accept the request if any signature verifies
7. Deduplicate using `webhook-id`

---

## Mock server reference implementation

The mock server in `tools/mock-server` mirrors the verification logic and can be
used as a reference implementation (not a hardened production consumer).

Standard Webhooks provides multi-language verification examples [here](https://github.com/standard-webhooks/standard-webhooks/tree/main/libraries).

### Single signing key

```bash
cd tools/mock-server
WEBHOOK_SECRET="whsec_..." cargo run
```

### Multiple signing keys (rotation support)

```bash
cd tools/mock-server
WEBHOOK_SECRET="whsec_old,whsec_new" cargo run
```

In multi-key mode the mock server verifies the signature against all active keys
and accepts the request if any signature matches.

---

## Verification failures

If signature verification fails:

- return a `4xx` response (typically `401` or `400`)
- do not process the payload
- do not retry internally
