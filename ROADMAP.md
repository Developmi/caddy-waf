# Roadmap

## ✅ Completed (v3.0.0)

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

## Current decisions

- No hard blockers in default compose flow.
- WAF default mode is `DetectionOnly`.
- Transition to `SecRuleEngine On` is required only after a prudent production observation window.
- Runtime values are environment-driven (`SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL`, `CADDY_WAF_IMAGE`, `EXAMPLE_APP_IMAGE`).
- Healthchecks are present at image level and compose level.
- All Caddy plugins use official upstream modules.
- Rate limiting uses `mholt/caddy-ratelimit` (pinned by commit SHA `5625512` - no release tags beyond v0.1.0).
- DNS challenge support uses `caddy-dns/cloudflare`.
- Security headers use Caddy's native `header` directive - no external plugin needed.

## Required production rollout sequence

1. Deploy with `SecRuleEngine DetectionOnly`.
2. Observe audit logs and tune CRS exclusions for 7–14 days.
3. Move to `SecRuleEngine On` after establishing a stable false-positive baseline.
4. Keep monitoring and refine CRS exclusions per application behavior.

## Pending - next priorities

### 1. Cloudflare token format compatibility
⚠️ Cloudflare now issues API tokens with `cfut_` / `cfat_` prefixes (since early 2026). `caddy-dns/cloudflare@v0.2.3` **rejects** this format. Fix: update to `@latest`. PR #123 in caddy-dns/cloudflare already added support.

### 2. Alpine base image migration
Alpine 3.21 (current) has **security support until November 2026**. Alpine 3.24 is the latest stable release. Plan migration before EOL.

### 3. Coraza-caddy issue monitor - HPACK bomb
Open issue [#316](https://github.com/corazawaf/coraza-caddy/issues/316) - "Potential HTTP/2 HPACK bomb memory exhaustion" in coraza-caddy v2.5.0. Not a published CVE yet, but warrants monitoring.

### 4. Kubernetes deployment profile
Add production-ready Kubernetes manifests: Deployment, Service, Ingress, ConfigMap, and HPA.

### 5. WAF rule hot-reload
Evaluate adding support for reloading WAF rules without container restart (e.g., via Caddy admin API).

### 6. Automated dependency updates
Integrate Dependabot or Renovate for automated tracking of Caddy, Coraza, CRS, and Alpine base image updates.

### 7. Testing and observability

- Add end-to-end FTW (Failure Tracking Web) test suite against the container image.
- Export structured WAF metrics for Prometheus.
- Add pre-built Grafana dashboard for WAF monitoring.

### 8. Compliance and operations

- Add formal deployment checklist per environment (Docker, systemd, K8s).
- Add incident response runbook for WAF false positives.
- Document SOC2 control mappings for WAF deployment.
- Add SLSA compliance documentation for the build pipeline.
