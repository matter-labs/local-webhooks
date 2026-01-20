# Verifying Signatures

Each webhook delivery includes a cryptographic signature that allows you to verify
that the request:

- originated from this service
- was not modified in transit
- is recent (protected against replay attacks)

Signature verification is **strongly recommended** for all production receivers.

---

## Signature header

Each request includes an `x-webhook-signature` header with the following format:

```bash
x-webhook-signature: t=<unix_timestamp>,v1=<hex_digest>
```

Where:

- `t` is a UNIX timestamp (seconds)
- `v1` is the HMAC-SHA256 signature (hex encoded)

Example:

```text
x-webhook-signature: t=1768843259,v1=d24fd15fe590092c5b3a644f565c670bf5d9987197b3337a88f5f09bbc620480
```

---

## Signing secret

Each webhook endpoint is associated with a **signing secret**.

- The secret is shared only between you and the service
- It is used as the HMAC key when computing the signature
- You must store it securely (treat it like an API key)
- This is included in the webhook creation response

> The signing secret is **not** included in webhook payloads or headers.

---

## Verification steps

To verify a webhook request:

1. Read the raw request body bytes
2. Extract `t` and `v1` from the `x-webhook-signature` header
3. Construct the signing input: `<t>.<raw_body>`
4. Compute the HMAC-SHA256 digest using your signing secret
5. Compare the computed digest to `v1`
6. Reject the request if verification fails

---

## Verification failures

If signature verification fails:

- return a `4xx` response (typically `401` or `400`)
- do **not** process the payload
- do **not** retry internally

The service may retry delivery depending on response code and timing.
