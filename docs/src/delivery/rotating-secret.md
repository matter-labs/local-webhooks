# Rotating Signing Keys

Rotate immediately if a signing key is exposed or suspected compromised.

Signing keys can be rotated per webhook endpoint. The new signing key is returned
once; store it securely.

---

## 1. Obtain the endpoint UUID

Several operations (such as signing key rotation) require the webhook endpoint
UUID. You can retrieve endpoint IDs using the list endpoints APIs. These endpoints
only return webhooks owned by the authenticated user.

### Address webhooks - list endpoints

```bash
curl "http://localhost:8081/v1/address-webhook?limit=20&offset=0" \
  -H "Authorization: Bearer <TOKEN>"
```

Each item in the response includes an `id` field:

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
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "contract": "0x32de7f85388d15365f87d96c94241a43880eba26",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b",
    "from_block": 31114,
    "status": "active"
  },
  "user_id": "G8df2r3YFnrG5gwpn7"
}
```

Use the value of `endpoint.id` as `<ENDPOINT_UUID>` in subsequent calls.

### Event webhooks - list endpoints

```bash
curl "http://localhost:8081/v1/event-webhook?limit=20&offset=0" \
  -H "Authorization: Bearer <TOKEN>"
```

Example response snippet:

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
    "chain_name": "zksyncos_prividium",
    "chain_id": 8022834,
    "contract": "0x32de7f85388d15365f87d96c94241a43880eba26",
    "topic0": "0xcf3dc07771cc79f08443885798a1e22d38a980af01eb51c3fd4b475afa81467b",
    "from_block": 31114,
    "status": "active"
  },
  "user_id": "G8df2r3YFnrG5gwpn7"
}
```

---

## 2. Rotate a signing key

The new signing key is returned once. Store it securely.

### Rotate event webhook signing key

```bash
curl -X POST "http://localhost:8081/v1/event-webhook/<ENDPOINT_UUID>/signing-keys/rotate" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "retire_after_secs": 86400,
    "version": "v1"
  }'
```

### Rotate address webhook signing key

```bash
curl -X POST "http://localhost:8081/v1/address-webhook/<ENDPOINT_UUID>/signing-keys/rotate" \
  -H "Authorization: Bearer <TOKEN>" \
  -H "Content-Type: application/json" \
  -d '{
    "retire_after_secs": 86400,
    "version": "v1"
  }'
```

---

## 3. Rotation parameters

All fields are optional:

```json
{}
```

- `retire_after_secs`
  - Overlap window where old and new keys are valid
  - Recommended: `86400` (24 hours)
- `version`
  - Signature version (`v1`)
  - Enables forward compatibility

---

## 4. Rotation response

The response includes:

- `signing_key` (returned once)
- `key_id`
- `version`

Signing keys cannot be retrieved again.

---

## 5. Support multiple signatures (required)

During rotation, webhook deliveries may include multiple signatures:

```
webhook-signature: v1,<sig1> v1,<sig2>
```

Consumers should:

- Iterate over all provided signatures
- Attempt verification with all active keys
- Accept the request if any signature verifies

---

## 6. Recommended rotation workflow

1. Rotate and store the new signing key.
2. Update consumers to accept both old and new keys.
3. Allow the overlap window to pass.
4. Remove the old key from your verifier.
