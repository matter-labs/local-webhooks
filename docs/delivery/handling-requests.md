# Handling Requests

Your webhook endpoint should be implemented as a **fast, resilient ingestion endpoint**.

Deliveries use **at-least-once** semantics and may be retried. Your handler must be
designed to acknowledge quickly, tolerate duplicates, and process payloads safely.

---

## Recommended receiver behavior

### Treat deliveries as at-least-once (idempotency required)

The same delivery may be sent more than once due to retries, network issues, or
receiver timeouts.

Your handler **must be idempotent**.

Recommended approaches:

- deduplicate using the `webhook-id` header (stable across retries)
- if you receive multiple endpoints on one URL, pair `webhook-id` with an endpoint identifier from the URL or payload
- design processing so re-running the same payload is safe

---

### Capture the raw request body

If you plan to verify webhook signatures, you must capture the **exact raw request
body bytes** before parsing.

Do:

- read raw bytes from the request
- store or verify them as-is
- parse JSON only after raw bytes are captured

Don’t:

- re-serialize parsed JSON for verification
- modify whitespace or ordering before verification

---

### Validate requests defensively

At minimum:

- require `Content-Type: application/json`
- enforce a maximum request body size
- apply request timeouts
- reject malformed payloads quickly with a `4xx` response

Fail fast on invalid input to reduce unnecessary retries.

---

### Keep synchronous work bounded

If synchronous processing is unavoidable:

- keep execution time short
- avoid slow downstream dependencies
- use strict timeouts and circuit breakers

Long-running synchronous work increases retry frequency and duplicate deliveries.

---

## Retries and backoff

Deliveries are retried when:

- your endpoint returns a non-2xx status
- your endpoint times out
- transient network failures occur

Local retry defaults (from `config/config.prividium.docker.toml`):

- `max_attempts`: `10`
- `base_backoff_secs`: `30`
- `max_backoff_secs`: `1800` (30 minutes)

Because retries are expected, idempotency is required.

---

## Headers to expect

Each webhook request includes standard HTTP headers plus service-specific metadata.

Common headers:

- `content-type: application/json`
- `webhook-id`
- `webhook-timestamp`
- `webhook-signature`

Example signature header:

```text
webhook-signature: v1,<sig1> v1,<sig2>
```

---

## Logging during development

During local testing, it can be helpful to log:

* `webhook-id`
* `webhook-timestamp`
* `type`
* the raw request body (or a truncated preview)

Avoid logging full payloads or secrets in production environments.
