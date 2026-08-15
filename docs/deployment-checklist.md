# Deployment checklist

Run these checklists for every deployment of caddy-waf — Docker Compose and
systemd (bare-metal). Kubernetes is **out of scope** and covered later.

The WAF defaults to `SecRuleEngine DetectionOnly` (Caddyfile.example:56): it logs
attacks but never blocks. Keep this mode for a 7–14 day observation window
before switching to `On`. See [incident-response.md](incident-response.md) if
you see unexpected blocking after enabling `On`.

## Quick path

1. Complete the pre-flight checks below.
2. Deploy with Docker Compose or systemd (pick one).
3. Run post-deploy verification.
4. Confirm the sign-off checklist.

## Pre-flight checks

All runtime values are environment-driven (see docker-compose.yml:6,33-39 and
README.md:228-235).

| Variable | Default | Required for | Check |
|----------|---------|--------------|-------|
| `SITE_ADDRESS` | `localhost` | Site address / server name | Set to your public domain when serving TLS via Let's Encrypt |
| `BACKEND_UPSTREAM` | `example-app:80` | Reverse proxy target | Point to your real backend (service name on the compose network, or host:port) |
| `ACME_EMAIL` | empty | Let's Encrypt certificate issuance | Set to a monitored mailbox (expiry warnings) |
| `CADDY_WAF_IMAGE` | `ghcr.io/developmi/caddy-waf:v3.3.2` | Image to run | Prefer an immutable digest (`@sha256:...`) in production |

- [ ] `.env` exists and has real values (`cp .env.example .env`, then edit)
- [ ] Runtime `Caddyfile` exists (`cp Caddyfile.example Caddyfile`) and matches
      your site (`{$SITE_ADDRESS}` block, `reverse_proxy` upstream)
- [ ] Image signature verified with Cosign before pulling in production
      (README.md:276-287)
- [ ] Ports 80/443 reachable from the internet (TLS challenge), or DNS already
      points to the server
- [ ] Backend is reachable from the host / compose network
- [ ] For systemd: Caddy binary, `/etc/caddy/Caddyfile`, `coraza.conf` and
      `owasp-crs/` rules are installed (see systemd section)

## Docker Compose deployment

Source of truth for the steps below: README.md:249-274 and docker-compose.yml.

1. Validate the compose file before anything else:

   ```bash
   docker compose config
   ```

2. Start the stack:

   ```bash
   docker compose up -d
   ```

3. Confirm both services are healthy:

   ```bash
   docker compose ps
   docker ps --filter "name=caddy-waf" --format "{{.Names}} {{.Status}}"
   ```

4. Check logs for clean startup and ACME success:

   ```bash
   docker compose logs --tail=50 caddy-waf
   ```

## systemd deployment (bare-metal)

Source of truth: deploy/systemd/caddy-waf.service and README.md:268-274.

The unit runs `/usr/bin/caddy run --environ --config /etc/caddy/Caddyfile` as
the `caddy-waf` user, so the runtime config and WAF rules live on disk, not in
a container:

- `/etc/caddy/Caddyfile` — site config for systemd, deployed from
  `deploy/systemd/Caddyfile.systemd` (zero-trust variant: admin API bound to
  loopback only). Do NOT reuse the compose runtime file — its admin bind
  assumes the container network
- `/etc/caddy/coraza.conf` and `/etc/caddy/owasp-crs/` — Coraza + CRS rules
  referenced by the Caddyfile `Include` directives
- State lands in `/var/lib/caddy-waf` (systemd `StateDirectory=caddy-waf`)

1. Create the service user and install the unit:

   ```bash
   sudo useradd -r -s /usr/sbin/nologin caddy-waf
   sudo cp deploy/systemd/caddy-waf.service /etc/systemd/system/
   sudo systemctl daemon-reload
   ```

2. Validate the Caddyfile before starting:

   ```bash
   sudo -u caddy-waf caddy validate --config /etc/caddy/Caddyfile
   ```

3. Enable and start:

   ```bash
   sudo systemctl enable --now caddy-waf
   ```

4. `SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL` are expanded from the
   process environment (`--environ`). Provide them via a drop-in:

   ```bash
   sudo systemctl edit caddy-waf
   ```

   ```ini
   [Service]
   Environment=SITE_ADDRESS=waf.example.com
   Environment=BACKEND_UPSTREAM=127.0.0.1:8080
   Environment=ACME_EMAIL=ops@example.com
   ```

   Then `sudo systemctl restart caddy-waf`.

5. Verify:

   ```bash
   sudo systemctl status caddy-waf
   journalctl -u caddy-waf --since "10 minutes ago"
   ```

## Post-deploy verification

- [ ] Container/service is running and restarted on failure
      (`restart: unless-stopped`, `Restart=on-failure`)
- [ ] Healthcheck passes: compose probes `curl -fs http://127.0.0.1:2019/metrics`
      every 30s (docker-compose.yml:40-45)
- [ ] Admin `/metrics` is reachable only on the internal network — port 2019 is
      **never** published to the host (Caddyfile.example:16-20); verify it is not
      published: `docker compose ps` shows only 80/443 on the host
- [ ] systemd: admin API is bound to **loopback only** (Caddyfile.systemd:21-25) —
      `ss -ltn` shows 2019 listening on `127.0.0.1`, never `*`
- [ ] WAF is in `DetectionOnly` (Caddyfile.example:56) unless your observation window
      is over — never enable `On` on day one
- [ ] A real request passes through: `curl -I https://yourdomain.com`
- [ ] Audit log line appears for your request (JSON, `waf_rule_id` present) —
      confirms Coraza is processing traffic
- [ ] Metrics flow to your scrape target (observability profile):
      `docker compose --profile observability-vm up -d` or
      `--profile observability-prom up -d` (README.md:351-397)

## Rollback

| Environment | Steps |
|-------------|-------|
| Docker Compose | 1. Restore the previous runtime `Caddyfile` (and `.env` image pin) from backup. 2. `docker compose up -d --force-recreate` — certificates persist in the `caddy_data` volume, no re-issuance storm |
| systemd | 1. Restore previous `/etc/caddy/Caddyfile` (and rules) from backup. 2. `sudo systemctl reload caddy-waf` for config-only rollback, or `sudo systemctl restart caddy-waf` |

If the rollback is caused by WAF blocking, first switch the site to
`DetectionOnly` and follow [incident-response.md](incident-response.md).

## Sign-off checklist

- [ ] `docker compose config` validates (Compose) or `caddy validate` passes (systemd)
- [ ] Correct `SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL`, `CADDY_WAF_IMAGE`
- [ ] Image digest pinned and Cosign-verified
- [ ] WAF in `DetectionOnly` (or `On` only after the observation window with
      tuned exclusions)
- [ ] Healthcheck green, logs clean, `/metrics` internal-only
- [ ] TLS certificate issued and request round-trips to the backend
- [ ] Rollback path documented and tested for this environment
