# Prometheus MCP

The read-only endpoint is `https://prometheus.est.unixpimps.net/mcp`.
Authelia at `https://auth.est.unixpimps.net` authenticates named users and issues
OAuth access tokens. Prometheus MCP on goose introspects each token, checks its
resource audience, expiry, subject and `prometheus.read` scope, and consumes the
credential before querying the local Prometheus instance. It does not forward the
user's OAuth token to Prometheus.

## Connect ChatGPT

Create a custom MCP connection with the endpoint above and OAuth authentication.
Use the predefined client ID `chatgpt-prometheus`. Retrieve its client secret in
your own terminal:

```fish
nix develop --command sops --decrypt --extract '["observability_chatgpt_client_secret"]' secrets/pakhet.yaml
```

Log in as `ij`. Retrieve the initial password in your terminal:

```fish
nix develop --command sops --decrypt --extract '["observability_ij_password"]' secrets/pakhet.yaml
```

The client requires PKCE S256 and uses `client_secret_post` for token exchange.
The pinned Authelia release does not implement RFC 8707 resource indicators;
each interactive client instead has exactly one allowed audience, granted by
`requested_audience_mode = "implicit"`. The MCP server verifies that audience
exactly. This is independent of consent, which remains explicit.
The configured ChatGPT redirect is
`https://chatgpt.com/connector_platform_oauth_redirect`. Discovery advertises
whether issuer identification is supported. If ChatGPT shows a connection-specific
callback instead, add that exact URL to the client's `redirect_uris` in
`modules/private/nixos/services/pakhet/observability-auth.nix` and redeploy pakhet.
Do not use wildcard callback URLs.

The public `prometheus-cli` client is available for other compatible clients using
PKCE with the callback `http://127.0.0.1:18443/callback`.

## Users and credentials

Users opt in with `observability = true` in
`modules/private/inventory/users.nix`. Each opted-in user needs
`observability_<username>_password_hash` in `secrets/pakhet.yaml`, containing an
Authelia-compatible Argon2id password hash. User names, display names, email
addresses and group membership are rendered declaratively; password reset in the
login UI is disabled so changes cannot diverge from sops.

Only `ij` is initially enabled. All enabled users can read the same Prometheus
dataset. Skills and dashboard visibility do not enforce per-service data access.

Signing keys, encryption keys and client hashes are encrypted with sops. The MCP
introspection credential is shared through `observability_mcp_client_secret` in
goose and pakhet's encrypted files; the corresponding hash is
`observability_mcp_client_hash` on pakhet. Rotate both together. Authelia persists
its database in `/var/lib/authelia-observability`; preserve it together with its
sops keys when moving the service. Tokens expire after 15 minutes and refresh
tokens after 30 days. The resource server uses online introspection and does not
cache successful checks.

## Service dashboards and skills

Register dashboards and optional authored Agent Skill directories in the same
monitoring module:

```nix
observability.services.example = {
  dashboards = dashboardDirectory;
  jobs = [ "example" ];
  skills = [ ./skills/check-example ];
};
```

The catalog provisions the dashboards and generates one discoverable skill per
dashboard, with representative PromQL, dashboard links and variable-resolution
guidance. Authored skills add operational context; each directory must contain
`SKILL.md` with a matching name and description in YAML frontmatter and an H1
heading. Duplicate and malformed skill names fail the build or server startup.
Skill changes restart the MCP service without recompiling its binary.

Discover and read skills through `runbooks_list` and `runbooks_read`. They are also
available through MCP prompts and `skill://` resources. The skills extension is a
draft; tool-based discovery is the portable interface.

## Limits and maintenance

The MCP tool list includes core query/discovery/docs/runbook tools plus targets,
alerts, rules, health/readiness and build information. Configuration, reload,
shutdown and TSDB administration tools are not exposed. TOON is enabled for the
upstream tools that encode structured data; query output retains upstream's
formatting. Output truncation is capped at 100 entries/lines, range queries at 600
intervals per series, backend requests at 20 seconds and concurrent MCP requests
at four. The public proxy applies request-size and rate limits as well.

The package pins the official source and documentation snapshots. Its local patch
adds OAuth protection, per-server external skills and enforced query limits. It
does not implement an OAuth authorization server. When updating upstream, rebase
the patch and run its Go tests, then build goose and pakhet before activation.

Cloudflare DNS reconciliation on pakhet manages only the explicitly declared
Prometheus and auth CNAMEs, using the existing sops-managed DNS API token. Both
point to `r0.est.unixpimps.net` with Cloudflare proxying disabled. It does not delete
unlisted records. Internal DNS aliases point directly to pakhet.

Deploy pakhet and goose serially after pushing the repository. Useful checks:

```fish
curl -i https://prometheus.est.unixpimps.net/mcp
curl https://prometheus.est.unixpimps.net/.well-known/oauth-protected-resource
curl https://auth.est.unixpimps.net/.well-known/openid-configuration
ssh pakhet.est.unixpimps.net sudo systemctl status authelia-observability cloudflare-dns
ssh r0.est.unixpimps.net sudo systemctl status prometheus-mcp
```
