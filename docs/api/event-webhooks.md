# Event Webhooks

Event webhooks notify your server when a specific on-chain event is observed.
Each event webhook consists of:

- A **webhook endpoint** (destination URL, name, signing key)
- A **single event subscription** (`contract` + `topic0` + optional `from_block`)

---

## Routes

| Method | Path |
|------|------|
| POST | `/v1/event-webhook` |
| GET | `/v1/event-webhook/{id}` |
| PATCH | `/v1/event-webhook/{id}` |
| DELETE | `/v1/event-webhook/{id}` |

All routes require authentication.

---

## Create Event Webhook

Create a new webhook endpoint and register an event subscription.

- A signing secret is generated automatically.
- The **plaintext signing key is returned only once**, in the create response.
- Store the signing key securely; it cannot be retrieved later.

### Request

```bash
curl -X POST http://localhost:8081/v1/event-webhook \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "My Mint Watcher",
    "url": "http://localhost:9000/webhook",
    "contract": "0x66EC845C0B07D1728B1b14921D561fe7963A5Ab8",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b"
  }'
````

### Response (`201 Created`)

```json
{
  "endpoint": {
    "id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "name": "My Mint Watcher",
    "url": "http://localhost:9000/webhook",
    "signing_key": "whsec_0f71ea604c43cea27fc8ccc37bbb523055b0cbf3b9927f1e5e516cc8d1f84e0a",
    "enabled": true
  },
  "subscription": {
    "id": "ec849e0b-8bf2-4d8a-ad4b-09afc0783e00",
    "endpoint_id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "contract": "0x66ec845c0b07d1728b1b14921d561fe7963a5ab8",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b",
    "from_block": 18128,
    "status": "active"
  },
  "user_id": "rCNv_z0CebSRbJd01N_0X"
}
```

---

## Get Event Webhook

Retrieve a single event webhook by ID.

### Request

```bash
curl -X GET http://localhost:8081/v1/event-webhook/{id} \
  -H "Authorization: Bearer <token>"
```

### Response (`200 OK`)

```json
{
  "endpoint": {
    "id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "name": "My Mint Watcher",
    "url": "http://localhost:9000/webhook",
    "enabled": true
  },
  "subscription": {
    "id": "ec849e0b-8bf2-4d8a-ad4b-09afc0783e00",
    "endpoint_id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "contract": "0x66ec845c0b07d1728b1b14921d561fe7963a5ab8",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b",
    "from_block": 18128,
    "status": "active"
  },
  "user_id": "rCNv_z0CbeSRbJd01N_0X"
}
```

> Note: `signing_key` is **not** returned on read operations.

---

## Update Event Webhook

Update mutable webhook fields.
The event subscription (`contract`, `topic0`, chain) cannot be changed.

### Request

```bash
curl -X PATCH http://localhost:8081/v1/event-webhook/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "url": "http://localhost:9000/webhook",
    "enabled": true
  }'
```

### Response (`200 OK`)

```json
{
  "endpoint": {
    "id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "name": "My Mint Watcher",
    "url": "http://localhost:9000/webhook",
    "enabled": true
  },
  "subscription": {
    "id": "ec849e0b-8bf2-4d8a-ad4b-09afc0783e00",
    "endpoint_id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "contract": "0x66ec845c0b07d1728b1b14921d561fe7963a5ab8",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b",
    "from_block": 18128,
    "status": "active"
  },
  "user_id": "rCNv_z0CebSRbJd01N_0X"
}
```

---

## Delete Event Webhook

Permanently deletes the webhook endpoint and its associated subscription.

### Request

```bash
curl -X DELETE http://localhost:8081/v1/event-webhook/{id} \
  -H "Authorization: Bearer <token>"
```

### Response (`204 No Content`)

No response body is returned.

---

## Validation Rules

- `contract` must be a valid EVM address.
- `topic0` must be a valid 32-byte hash.
- Invalid input results in `400 BadRequest`.
- Unknown or unauthorized IDs result in `404 NotFound`.

---

## Signing Key Handling

- A signing key is generated on creation.
- The plaintext value is returned **only once**.
- See for more information
