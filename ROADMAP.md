# Roadmap

Every completed item links to the exact commit that delivered it — verify with `git show <hash>`.

## Completed (v3.0.0)

- **Caddy 2.11.4 upgrade** - Resolves 9 CVEs including 2 CRITICAL (CVE-2026-27590, CVE-2026-27587).
- **Supply chain hardening**
  - ✅ GitHub Actions pinned by commit SHA.
  - ✅ SBOM generation (CycloneDX) and artifact signing (Cosign keyless OIDC).
  - ✅ Trivy vulnerability scanning with CRITICAL/HIGH severity gate.
  - ✅ Cosign attestation + SLSA build provenance in CI pipeline.
  - ✅ SHA256 verification for OWASP CRS and Coraza configuration downloads.
  - ✅ apk version pinning (wget, tar).
- **Runtime hardening**
  - ✅ Read-only rootfs, cap_drop ALL, no-new-privileges, tmpfs noexec.
  - ✅ Process verification healthcheck at image and compose level.
  - ✅ Non-root execution (UID/GID 1337).
- **Documentation**
  - ✅ Unified SECURITY.md (policy + resolved CVEs).
  - ✅ TUNING.md with application-specific CRS exception guides.
  - ✅ CHANGELOG.md with full version history.

## Completed since v3.0.0 (traceability)

| Item | Commit | What / where |
|------|--------|--------------|
| 1. Cloudflare token format compatibility | → `dbae4fa` | `caddy-dns/cloudflare` pinned to v0.2.4 (`CADDY_DNS_CLOUDFLARE_REF`, Dockerfile) — accepts `cfut_`/`cfat_` API tokens |
| 6. Automated dependency updates | → `87c7c93` | Dependabot for Docker + GitHub Actions (.github/dependabot.yml) |
| 7a. FTW test suite | → `dbae4fa` | go-ftw integration suite, `make test-waf`, 4 cases (tests/) |
| 7b. WAF metrics | → `ba09d40` | Dual-backend observability — VictoriaMetrics + Prometheus scrape the same `metrics/prometheus.yml`; `caddy_http_*` series on admin /metrics |
| 7c. Grafana dashboard | → `ba09d40` | Provisioned datasources + dashboard (grafana/), profiles `observability-vm` / `observability-prom` |
| 8a. Deployment checklists | → `bccfc2f` | docs/deployment-checklist.md — Docker Compose + systemd only; Kubernetes intentionally out of scope for now (item 3 below) |
| 8b. IR runbook | → `bccfc2f` | docs/incident-response.md — WAF false positives, remediation, severity table |
| 8c. SOC2 mappings | → `bccfc2f` | docs/soc2-mappings.md — TSC mapped to implemented controls with file:line evidence |
| 8d. SLSA compliance | → `bccfc2f` | docs/slsa-compliance.md — current level L2 (partial L3), honest gap list |

**Observability decision:** the same `metrics/prometheus.yml` feeds both backends (VictoriaMetrics via `-promscrape.config`, Prometheus via `--config.file`) — Caddy's /metrics output needs no changes per backend. Admin `:2019` stays internal-only.

**coraza-caddy v2.5.0 limitation (upstream-watch, not a regression):** the plugin exports **no** `coraza_waf_*` metrics. WAF visibility comes from `caddy_http_*` series, the dashboard WAF-mode panel, and JSON audit logs. Revisit when upstream adds metrics.

## Current decisions

- No hard blockers in default compose flow.
- WAF default mode is `DetectionOnly`; transition to `SecRuleEngine On` only after a prudent production observation window.
- Runtime values are environment-driven (`SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL`, `CADDY_WAF_IMAGE`, `EXAMPLE_APP_IMAGE`).
- Healthchecks at image level and compose level.
- All Caddy plugins use official upstream modules.
- Rate limiting uses `mholt/caddy-ratelimit` (pinned by commit SHA `5625512` — no release tags beyond v0.1.0).
- DNS challenge support uses `caddy-dns/cloudflare`.
- Security headers use Caddy's native `header` directive — no external plugin needed.

## Required production rollout sequence

1. Deploy with `SecRuleEngine DetectionOnly`.
2. Observe audit logs and tune CRS exclusions for 7–14 days.
3. Move to `SecRuleEngine On` after establishing a stable false-positive baseline.
4. Keep monitoring and refine CRS exclusions per application behavior.

## Pending — next priorities

### 1. Alpine 3.24 base image migration
The image currently runs on **Alpine 3.23** (CHANGELOG.md:26,33) — not 3.21 — with security support until ~November 2026. Migrate to Alpine 3.24 before EOL; the build-time `apk upgrade` keeps 3.23 patched in the meantime.

### 2. Coraza-caddy issue monitor — HPACK bomb
Open issue [#316](https://github.com/corazawaf/coraza-caddy/issues/316) — "Potential HTTP/2 HPACK bomb memory exhaustion" in coraza-caddy v2.5.0. Not a published CVE yet, but warrants monitoring.

### 3. Kubernetes deployment profile
Production-ready K8s manifests (Deployment, Service, Ingress, ConfigMap, HPA). Still pending — the v3.3.x deployment checklists are intentionally Docker + systemd only.

### 4. WAF rule hot-reload
Evaluate reloading WAF rules without container restart (e.g., via Caddy admin API).

### 5. Expand go-ftw integration test coverage
The CI gate (`test-waf.yml`) runs the 4-case baseline suite (allow + SQLi/XSS/traversal) on every PR and push to main. Planned scale-up: more OWASP CRS vectors (e.g., REQUEST-920 protocol attacks) and a WAF-mode matrix (DetectionOnly vs On).
