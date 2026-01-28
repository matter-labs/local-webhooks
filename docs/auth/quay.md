# Quay Login

The webhook-service image is hosted on Quay and requires credentials from Matter Labs.

Recall this is only necessary when running the Webhook service locally.

Set the following values in `.env`:

- `DOCKER_USERNAME`
- `DOCKER_PASSWORD`

Then run:

```bash
make login
```

This calls `docker login quay.io` with the values from `.env`.

Repeat the login if credentials rotate or Docker clears its credential store.
