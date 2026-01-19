# Address Webhooks

Address webhooks notify your server when activity occurs involving one or more
on-chain addresses.

Each address webhook consists of:

- A **webhook endpoint** (destination URL, name, signing key)
- An **address subscription** containing one or more monitored addresses
- Optional `from_block` to control where monitoring begins

---

## Routes

| Method | Path |
|------|------|
| POST | `/v1/address-webhook` |
| GET | `/v1/address-webhook/{id}` |
| PATCH | `/v1/address-webhook/{id}` |
| DELETE | `/v1/address-webhook/{id}` |
| GET | `/v1/address-webhook/{id}/addresses` |
| POST | `/v1/address-webhook/{id}/addresses` |
| DELETE | `/v1/address-webhook/{id}/addresses` |

All routes require authentication.

---

## Create Address Webhook

Create a new webhook endpoint and register an address subscription.

- A signing secret is generated automatically.
- The **plaintext signing key is returned only once**, in the create response.
- Store the signing key securely; it cannot be retrieved later.

### Request

```bash
curl -X POST http://localhost:8081/v1/address-webhook \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "name": "webhook-address",
    "url": "http://localhost:9000/webhook",
    "addresses": [
      "0x0e9c68525eA0739f9f013c8042cFe8CD1f323C19",
      "0x5A39B3f95812DC1E902ab745A8FB5894a8ab8897"
    ]
  }'
````

### Response (`201 Created`)

```json
{
  "endpoint": {
    "id": "7ef711b5-26aa-4989-860a-9305f3f3715f",
    "name": "webhook-address",
    "url": "http://localhost:9000/webhook",
    "signing_key": "whsec_38f30005e37490b6656b278f99547a9a9453ca4d472feefd0983054802a5373c",
    "enabled": true
  },
  "subscription": {
    "id": "79657e71-403a-4be0-94aa-ca83b03d9d98",
    "endpoint_id": "7ef711b5-26aa-4989-860a-9305f3f3715f",
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "from_block": 19122,
    "status": "active"
  },
  "user_id": "Rz4ovpmb-1--qLH3HZv_y"
}
```

---

## Get Address Webhook

Retrieve a single address webhook by ID.

### Request

```bash
curl -X GET http://localhost:8081/v1/address-webhook/{id} \
  -H "Authorization: Bearer <token>"
```

### Response (`200 OK`)

```json
{
  "endpoint": {
    "id": "7ef711b5-26aa-4989-860a-9305f3f3715f",
    "name": "webhook-address",
    "url": "http://localhost:9000/webhook",
    "enabled": true
  },
  "subscription": {
    "id": "79657e71-403a-4be0-94aa-ca83b03d9d98",
    "endpoint_id": "7ef711b5-26aa-4989-860a-9305f3f3715f",
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "from_block": 19122,
    "status": "active"
  },
  "user_id": "Rz4ovpmb-1--qLH3HZv_y"
}
```

> Note: `signing_key` is **not** returned on read operations.

---

## Update Address Webhook

Update mutable webhook fields.

### Request

```bash
curl -X PATCH http://localhost:8081/v1/address-webhook/{id} \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "url": "http://localhost:9000/webhook"
  }'
```

### Response (`200 OK`)

```json
{
  "endpoint": {
    "id": "5b2a8400-d965-48c5-b74d-bf83c33d13be",
    "name": "My Address Watcher",
    "url": "http://localhost:9000/webhook",
    "enabled": true
  },
  "subscription": {
    "id": "3094fe85-0a19-4b95-afdf-756ab3697257",
    "endpoint_id": "5b2a8400-d965-48c5-b74d-bf83c33d13be",
    "chain_name": "zksyncos_sepolia",
    "chain_id": 8022705,
    "from_block": 100896,
    "status": "active"
  }
}
```

---

## Delete Address Webhook

Permanently deletes the webhook endpoint and its associated subscription.

### Request

```bash
curl -X DELETE http://localhost:8081/v1/address-webhook/{id} \
  -H "Authorization: Bearer <token>"
```

### Response (`204 No Content`)

No response body is returned.

---

## Manage Addresses

### List Addresses

```bash
curl -X GET http://localhost:8081/v1/address-webhook/{id}/addresses \
  -H "Authorization: Bearer <token>"
```

```json
{
  "addresses": [
    "0x0e9c68525ea0739f9f012c8042cfe8cd1f323c19",
    "0x5a39b3f95812dc1e942ab757a8fb5894a8ab8897"
  ]
}
```

---

### Add Addresses

- At least **one address** is required.

```bash
curl -X POST http://localhost:8081/v1/address-webhook/{id}/addresses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "addresses": [
      "0x1111111111111111111111111111111111111111"
    ]
  }'
```

**Response:** `204 No Content`

---

### Remove Addresses

```bash
curl -X DELETE http://localhost:8081/v1/address-webhook/{id}/addresses \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer <token>" \
  -d '{
    "addresses": [
      "0x1111111111111111111111111111111111111111"
    ]
  }'
```

**Response:** `204 No Content`

---

## Validation Rules

- All addresses must be valid EVM addresses.
- Unknown or unauthorized IDs result in `404 NotFound`.

---

## Signing Key Handling

- A signing key is generated on creation.
- The plaintext value is returned **only once**.
- If the key is lost or exposed, rotate it immediately
  (see **Webhook Delivery → Rotating the Signing Secret**).
