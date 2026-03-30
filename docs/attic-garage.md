# Attic + Garage on pakhet

This rollout deploys Garage as the S3-compatible backend for Attic on `pakhet`, with:

- Garage S3 API proxied at `https://s3.unixpimps.net`
- Attic API and path-based substituter endpoint at `https://nix-cache.unixpimps.net`
- Wildcard pull routing for `<cache>.nix-cache.unixpimps.net`
- Initial live public cache: `https://ijohanne.nix-cache.unixpimps.net`

## Secrets

`secrets/pakhet.yaml` now carries the required secret material:

- `garage_rpc_secret`
- `garage_admin_token`
- `garage_metrics_token`
- `garage_attic_key_id`
- `garage_attic_secret_key`
- `attic_token_rs256_secret_base64`

## Deployment Order

1. Push the repo changes.
2. Deploy pakhet.
3. Verify `garage.service`, `garage-bootstrap.service`, `atticd.service`, and `attic-bootstrap.service`.
4. Confirm that `ijohanne` exists and is public.

Recommended verification commands on `pakhet`:

```bash
systemctl status garage garage-bootstrap atticd attic-bootstrap
garage status
garage bucket info attic
atticd-atticadm make-token --sub verify --validity '10m' --pull ijohanne
```

## What Gets Bootstrapped

`garage-bootstrap.service` is idempotent and will:

- assign the single-node Garage layout if the node is still unassigned
- import the pre-generated Attic S3 key from sops
- create the `attic` bucket
- grant the Attic key `read`, `write`, and `owner` access on that bucket

`attic-bootstrap.service` is idempotent and will:

- mint a short-lived bootstrap token via `atticd-atticadm`
- create the `ijohanne` cache if it does not exist
- force the cache to be public
- write the current cache info to `/var/lib/attic-bootstrap/ijohanne.info`

## Push Token Issuance

Issue a restricted token for `ijohanne` with:

```bash
atticd-atticadm make-token \
  --sub ijohanne-push \
  --validity '1 year' \
  --pull ijohanne \
  --push ijohanne
```

For a cache owner that should also be allowed to create future caches under a prefix:

```bash
atticd-atticadm make-token \
  --sub opsplaza \
  --validity '1 year' \
  --pull 'opsplaza-*' \
  --push 'opsplaza-*' \
  --create-cache 'opsplaza-*' \
  --configure-cache 'opsplaza-*' \
  --configure-cache-retention 'opsplaza-*'
```

## Public Pull Verification

The wildcard vhost rewrites `<cache>.nix-cache.unixpimps.net` to the internal Attic path namespace for public pulls.

Check the public cache surface with:

```bash
curl https://ijohanne.nix-cache.unixpimps.net/nix-cache-info
curl -I https://ijohanne.nix-cache.unixpimps.net/
```

## Important Attic Limitation

Attic only exposes one global `substituter-endpoint` prefix in `cache-config` responses. That means:

- `attic use ijohanne` will advertise the path-based endpoint under `https://nix-cache.unixpimps.net/ijohanne`
- the wildcard hostname `https://ijohanne.nix-cache.unixpimps.net` still works for direct public pulls
- if you want the vanity hostname in manual Nix config, add it explicitly instead of relying on `attic use`

This behavior comes from Attic appending the cache name to one configured substituter base URL.
