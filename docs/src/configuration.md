# Configuration

Local configuration is split across three places:

- `.env` for host-side settings and secrets (ports, credentials, keys)
- `config/config.prividium.docker.toml` for service configuration (ports, delivery, workers, chain)
- `docker-compose.yml` for container wiring (port bindings, volume mounts)

Changes to config files require restarting the containers.

---

## Use a custom config file

By default, Docker Compose mounts `config/config.prividium.docker.toml` into the
container at `/config/config.toml`. To use a different file, set:

```
HOST_CONFIG_PATH=./path/to/your-config.toml
```

Then restart the stack.

---

## Change API or admin ports

There are two layers of ports:

- **Service ports (inside the container)** from `config/config.prividium.docker.toml`:
  - `[server].api_port`
  - `[server].admin_port`
- **Host ports (on your machine)** from `.env`:
  - `API_PORT`
  - `ADMIN_PORT`

### Change only the host port

If you only want to expose the service on a different host port, update `.env`:

```
API_PORT=8081
ADMIN_PORT=8080
```

The service continues to listen on the same container ports.

### Change the service port inside the container

If you want the service to listen on different internal ports:

1. Update `config/config.prividium.docker.toml`:

   ```
   [server]
   api_port = 8081
   admin_port = 8080
   ```

2. Update `docker-compose.yml` to map host ports to the new container ports.
   The right-hand side of the mapping must match the config file:

   ```
   ports:
     - "${API_PORT:-8081}:8081"
     - "${ADMIN_PORT:-8080}:8080"
   ```

3. Update the `webhook-service` healthcheck in `docker-compose.yml` to use the
   new admin port.

---

### Payload Pruning (`[payload_pruning]`)
Controls retention and pruning of delivery job payloads.

```toml
[payload_pruning]
interval_secs = 3600   # Run every hour
retention_days = 7      # Keep payloads for 7 days
batch_size = 5000       # Max rows pruned per batch
```

## Other common settings

Use `config/config.prividium.docker.toml` to tune:

- log level: `[server].log_level`
- retries/backoff: `[delivery]`
- worker concurrency: `[workers].concurrency`
- chain RPC and polling: `[chain]` and `[chain.auth]`
