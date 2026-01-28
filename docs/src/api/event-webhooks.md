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
| GET | `/v1/event-webhook` |
| GET | `/v1/event-webhook/{id}` |
| PATCH | `/v1/event-webhook/{id}` |
| DELETE | `/v1/event-webhook/{id}` |

All routes require authentication.

---

## List Event Webhooks

List all event webhooks owned by the authenticated user. This is the best way
to obtain the endpoint UUIDs used by get, update, delete, and signing key
rotation endpoints.

### Request

```bash
curl "http://localhost:8081/v1/event-webhook?limit=20&offset=0" \
  -H "Authorization: Bearer <TOKEN>"
```

### Response (`200 OK`)

Each item includes an `endpoint.id` field. Use that value as `<ENDPOINT_UUID>` in
subsequent calls.

Example item:

```json
{
  "endpoint": {
    "id": "a5113c41-18f3-45a7-b1cd-3acbf8a3f489",
    "name": "example-event-webhook",
    "url": "http://host.docker.internal:9000/webhook",
    "enabled": true
  },
  "subscription": {
    "id": "9592c92a-19f7-4ee4-9ed1-945293f6fd2d",
    "endpoint_id": "a5113c41-18f3-45a7-b1cd-3acbf8a3f489",
    "chain_name": "prividium_testnet",
    "chain_id": 8022834,
    "contract": "0x32de7f85388d15365f87d96c94241a43880eba26",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b",
    "from_block": 31114,
    "status": "active"
  },
  "user_id": "G8df2r3YFnrG5gwpn7rzD"
}
```

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
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "name": "My Mint Watcher",
    "url": "http://host.docker.internal:9000/webhook",
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
    "url": "http://host.docker.internal:9000/webhook",
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
  "user_id": "rCNv_z0CebSRbJd01N"
}
```

---

## Get Event Webhook

Retrieve a single event webhook by ID.

### Request

```bash
curl -X GET http://localhost:8081/v1/event-webhook/<ENDPOINT_UUID> \
  -H "Authorization: Bearer <TOKEN>"
```

### Response (`200 OK`)

```json
{
  "endpoint": {
    "id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "name": "My Mint Watcher",
    "url": "http://host.docker.internal:9000/webhook",
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
  "user_id": "rCNv_z0CbeSRbJd01N"
}
```

> Note: `signing_key` is **not** returned on read operations.

---

## Update Event Webhook

Update mutable webhook fields.
The event subscription (`contract`, `topic0`, chain) cannot be changed.

### Request

```bash
curl -X PATCH http://localhost:8081/v1/event-webhook/<ENDPOINT_UUID> \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <TOKEN>" \
  -d '{
    "url": "http://host.docker.internal:9000/webhook",
    "enabled": true
  }'
```

### Response (`200 OK`)

```json
{
  "endpoint": {
    "id": "588793f2-42bf-496f-ac46-a7cd7cd3bc08",
    "name": "My Mint Watcher",
    "url": "http://host.docker.internal:9000/webhook",
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
  "user_id": "rCNv_z0CebSRbJd01N"
}
```

---

## Delete Event Webhook

Permanently deletes the webhook endpoint and its associated subscription.

### Request

```bash
curl -X DELETE http://localhost:8081/v1/event-webhook/<ENDPOINT_UUID> \
  -H "Authorization: Bearer <TOKEN>"
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
- See **Webhook Delivery → Rotating Signing Keys** for rotation and overlap details.
