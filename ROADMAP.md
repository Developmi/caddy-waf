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
| 7a. FTW test suite | → `dbae4fa` | go-ftw integration suite, `make test-waf`, 20 cases (tests/integration) |
| 7b. WAF metrics | → `ba09d40` | Dual-backend observability — VictoriaMetrics + Prometheus scrape the same `metrics/prometheus.yml`; `caddy_http_*` series on admin /metrics |
| 7c. Grafana dashboard | → `ba09d40` | Provisioned datasources + dashboard (grafana/), profiles `observability-vm` / `observability-prom` |
| 8a. Deployment checklists | → `bccfc2f` | docs/deployment-checklist.md — Docker Compose + systemd only; Kubernetes intentionally out of scope for now (item 3 below) |
| 8b. IR runbook | → `bccfc2f` | docs/incident-response.md — WAF false positives, remediation, severity table |
| 8c. SOC2 mappings | → `bccfc2f` | docs/soc2-mappings.md — TSC mapped to implemented controls with file:line evidence |
| 8d. SLSA compliance | → `bccfc2f` | docs/slsa-compliance.md — current level L2 (partial L3), honest gap list |

**Observability decision:** the same `metrics/prometheus.yml` feeds both backends (VictoriaMetrics via `-promscrape.config`, Prometheus via `--config.file`) — Caddy's /metrics output needs no changes per backend. Admin `:2019` stays internal-only.

**coraza-caddy v2.5.0 limitation (upstream-watch, not a regression):** the plugin exports **no** `coraza_waf_*` metrics. WAF visibility comes from `caddy_http_*` series, the dashboard WAF-mode panel, and JSON audit logs. Revisit when upstream adds metrics.

**Coraza version alignment (verified 2026-08-21):** coraza-caddy v2.5.0 embeds the **coraza engine v3.7.0** (go.mod at tag v2.5.0), and the `coraza.conf-recommended` downloaded at build time (tag v3.7.0, SHA256-pinned) matches the embedded engine exactly. Engine >= 3.3.3 → CVE-2025-29914 (GHSA-q9f5-625g-xm39) does not apply. coraza-caddy v2.5.0 is the latest tagged plugin release; upstream main already targets Caddy v2.11.4.

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
The image currently runs on **Alpine 3.23.5** (verified 2026-08-21 from the `caddy:2.11.4` official image — the Alpine base is fixed by the upstream Caddy image, so an independent base swap would break the pinned Caddy 2.11.4 build). Alpine 3.23 EOL is **2027-11-01** (stack.watch / eosl.date). Migrate to Alpine 3.24 (current, EOL 2028-06-01) once Caddy publishes an image on it; the build-time `apk upgrade` keeps 3.23 packages patched in the meantime.

### 2. Coraza-caddy issue monitor — HPACK bomb
Open issue [#316](https://github.com/corazawaf/coraza-caddy/issues/316) — "Potential HTTP/2 HPACK bomb memory exhaustion" in coraza-caddy v2.5.0 (opened 2026-06-09, re-verified open 2026-08-21; context: HTTP/2 "Bomb" class disclosed June 2026, e.g. CVE-2026-49975). Not a published CVE for coraza-caddy yet, but warrants monitoring.

### 3. Kubernetes deployment profile
Production-ready K8s manifests (Deployment, Service, Ingress, ConfigMap, HPA). Still pending — the v3.3.x deployment checklists are intentionally Docker + systemd only.

### 4. WAF rule hot-reload
Evaluate reloading WAF rules without container restart (e.g., via Caddy admin API).

### 5. Expand go-ftw integration test coverage
Expanded (2026-08-21) from 4 to **20 cases**: baseline (4) + OWASP CRS core (10: SQLi, XSS, MSSQL, RCE, PHP exec, RFI/SSRF, LFI, header injection, unicode XSS) + bypass (6: false-positive check, double-encoding, header-based payloads, POST JSON body, fullwidth XSS), mapped to OWASP Top 10 2025 (A03 strong coverage). Remaining: REQUEST-920 protocol attacks and a WAF-mode matrix (DetectionOnly vs On).

### 6. mTLS remote administration (contract §6 target state)
Enable Caddy's remote admin listener (`admin.remote`, default `:2021`) with mutual TLS — `admin.identity` (issuer: internal/local CA) + `access_control[].public_keys` (base64 DER client certs) + path/method permissions. **JSON config only** — the Caddyfile `admin` block cannot express identity/remote (upstream `options.go` supports only `origins`/`enforce_origin`). Requires: systemd deployment moves from Caddyfile to a JSON config, client-cert issuance/rotation from the local PKI CA (`pki/authorities/local`, Smallstep-backed), and the plaintext local endpoint stays on loopback (it has no TLS/mTLS capability upstream). Upstream marks remote admin EXPERIMENTAL — re-validate before adopting.

### 7. UI client certificates (caddy-waf-ui mTLS consumer)
TLS client support in the UI's admin client: `tls.Config` with client certificate + local-CA root, `CADDY_ADMIN_URL` https, env-driven cert paths; contract INTEGRATION.md §4/§10 updates. Unblocks mTLS remote admin end-to-end (items 6 + this one are the §6 target pair).

### 8. Review follow-ups — 4R v3.3.2 (non-blocking findings, tracked for cleanup)
All findings below are WARNING/SUGGESTION from the v3.3.2 4R review (lineage `review-004a497aff6bb2fa`) — none block the release; they are tracked here so nothing is left loose.

| # | Location | Issue | Suggested fix |
|---|----------|-------|---------------|
| 8.1 | `.github/workflows/docker-build-scan-sign.yml:205-206` | Build summary has an explicit `if:` (replaces implicit `success()`) — on failed tag runs it still prints "🎉 Build Successful!" + docker pull, right after the rollback step | Add `success()` to the step's `if:` condition |
| 8.2 | `.github/workflows/docker-build-scan-sign.yml:189` | Rollback coverage gaps: run cancellation after push → `failure()` false → rollback never runs; partial multi-arch push → digest unset → guard skips cleanup with tag partially live | Consider `always()` + pre-push state check, or document manual retry |
| 8.3 | `docs/deployment-checklist.md:105` | `enable --now` (step 3) runs before the ACME_EMAIL drop-in (step 4, :116-120) — first boot uses `example.com` defaults and attempts ACME (noise/backoff) | Reorder steps or document the transient state |
| 8.4 | `README.md:467-468` | Release-table anchors `#200---2026-03-14` / `#100---2026-02-09` miss the real GitHub id suffix (`-made-in-deprecated-repo`) — fragment navigation broken for 2.0.0/1.0.0 | Complete the anchors with the real ids |
| 8.5 | `docs/soc2-mappings.md:35,46` | Stale ranges `:5,98-149` / `:111-149` vs real cosign sign `:158-166`, attest `:168-176`, SLSA `:178-184` | Re-cite against the current workflow |
| 8.6 | `docs/deployment-checklist.md:34` | Cites cosign verify at `README.md:276-287`; the command is actually at `:290-295` | Update the cited range |
| 8.7 | `README.md:450` | Consecutive `---` horizontal rules (450 and 454) above the releases table | Remove one separator |
| 8.8 | `docs/soc2-mappings.md:28` | Cites `README.md:345-347`; the "no `coraza_waf_*` metrics" note is at `:355-357` | Update the cited range |
