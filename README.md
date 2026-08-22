# Vikunja MCP

Combined container with the official Vikunja 2.5.0 binary,
`democratize-technology/vikunja-mcp` 0.2.2 and Supergateway 3.4.3.

- Vikunja Web/API: port `3456`
- Streamable HTTP MCP: `http://vikunja-mcp:8000/mcp`
- MCP health: `http://vikunja-mcp:8000/healthz`
- Public WebUI in this deployment: `https://ucore.tailb13f39.ts.net:2105/`

The MCP endpoint requires `Authorization: Bearer <Vikunja API token>`. Each
MCP session gets its own stdio child and token; no global API token is stored in
the container environment. The same bearer is required for every request in the
session.

Container builds and pushes run only in GitHub Actions. For deployment, first
run `sudo podman-smart1.sh --update`, then run `./setup.sh` as the target user.
The setup script only renders and starts the pinned image already present in the
user's Podman store.
