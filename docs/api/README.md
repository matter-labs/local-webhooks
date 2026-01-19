# Using the API

The local API listens on `http://localhost:8081` by default (see `API_PORT` in `.env`).
When you run `make up`, the routes are shown under the `/v1` prefix.
Paths in this section are relative to the API base.
Webhook IDs used in path parameters come from create or list responses.
If your deployment uses a different prefix, keep the relative paths unchanged.

All routes require authentication; see the SIWE Token page for a helper script.

Common behavior:

- Create endpoints return a plaintext signing key only once.
- Success responses use `201` (create), `200` (get/list/update), or `204` (delete).
- Error keys include `BadRequest` and `NotFound`.
