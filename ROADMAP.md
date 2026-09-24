# Roadmap

Every completed item links to the exact commit or PR that delivered it — verify with `git show <hash>`.

## Completed (v3.0.0)

- **Caddy 2.11.4 upgrade** — Resolves 9 CVEs including 2 CRITICAL (CVE-2026-27590, CVE-2026-27587).
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

| Item | Commit / PR | What / where |
|------|-------------|--------------|
| 1. Cloudflare token format compatibility | → `dbae4fa` | `caddy-dns/cloudflare` pinned to v0.2.4 (`CADDY_DNS_CLOUDFLARE_REF`, Dockerfile) — accepts `cfut_`/`cfat_` API tokens |
| 2. Automated dependency updates | → `87c7c93` | Dependabot for Docker + GitHub Actions (.github/dependabot.yml) |
| 3. FTW integration test suite (v1) | → `dbae4fa` | Initial go-ftw integration suite, `make test-waf`, 20 cases (tests/integration) |
| 4. Dual-backend observability & Grafana | → `ba09d40` | VictoriaMetrics + Prometheus scrape `metrics/prometheus.yml`; Grafana dashboard with profiles `observability-vm` / `observability-prom` |
| 5. Operations & compliance docs | → `bccfc2f` | `docs/deployment-checklist.md`, `docs/incident-response.md`, `docs/soc2-mappings.md`, `docs/slsa-compliance.md` |
| 6. Bare-boot regression gate | → `e6504b1` | `make test-boot` verifying baked container boots as UID 1337 with zero volume mounts |
| 7. Coraza WAF 2.6.1 & gRPC CVE resolution | → `ca333f4` (#33) | Bumped `coraza-caddy` to v2.6.1, `grpc` to v1.83.2, resolved `CVE-2026-84304` & `CVE-2026-84445`; `.trivyignore` fully emptied |
| 8. OWASP CRS Suite Expansion (122 cases) | → `58e8be2` (#35) | Reorganized under Screaming Architecture: 122 tests covering 12 CRS families, evasion, baseline, Node.js RCE, SSTI, Prototype Pollution, and false-positive baselining |
| 9. Native Caddy perimeter defense-in-depth | → `f1bf460` (#36) | Enforced `@sensitive_paths` blocking `.git`, `.env`, `.aws`, `.docker`, `*.sql` at Caddy level even in DetectionOnly; added `(security_headers)` suppressing `Server` and `X-Powered-By` banners |
| 10. Granular Makefile test targets | → `f1bf460` (#36) | Fast targets (`make test-baseline`, `make test-evasion`, `make test-hardening`, `make test-crs`, `make test-suite SUITE=...`) |
| 11. Mandatory CI Functional Test Gate | → `58e8be2` (#35) | Releases gated on full `make test-waf` + `make test-boot` passing green before Cosign signing and push |
| 12. Version alignment & anti-hype cleanup | → `c68449d` (#37) | Version bump v3.5.5, documentation alignment across OCI labels, compose, checklist, and removal of marketing hype |

**Observability note:** The same `metrics/prometheus.yml` feeds both backends (VictoriaMetrics via `-promscrape.config`, Prometheus via `--config.file`) — Caddy's `/metrics` output needs no changes. Admin `:2019` remains internal-only.

**coraza-caddy metrics status:** Up to `v2.6.1`, the plugin exports no `coraza_waf_*` metrics (upstream limitation tracked in [coraza-caddy#82](https://github.com/corazawaf/coraza-caddy/issues/82)). Visibility is provided via `caddy_http_*` series, dashboard WAF-mode indicators, and structured JSON audit logs on stdout.

## Current architectural decisions

- No hard blockers in default compose flow.
- WAF default mode is `DetectionOnly`; transition to `SecRuleEngine On` only after an observation window.
- Runtime values are environment-driven (`SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL`, `CADDY_WAF_IMAGE`).
- Multi-layer perimeter defense: Caddy native path blocking + header suppression precedes WAF evaluation.
- Healthchecks at image level and compose level.
- All Caddy plugins use official upstream modules.
- Rate limiting uses `mholt/caddy-ratelimit` (pinned by commit SHA `5625512`).
- DNS challenge support uses `caddy-dns/cloudflare` (v0.2.4).
- Security headers and banner suppression use Caddy's native `header` directive — no external plugin needed.

## Required production rollout sequence

1. Deploy with `SecRuleEngine DetectionOnly`.
2. Observe audit logs and tune CRS exclusions for 7–14 days.
3. Move to `SecRuleEngine On` after establishing a stable false-positive baseline.
4. Keep monitoring and refine CRS exclusions per application behavior.

## Pending — Next priorities

### 1. Kubernetes deployment profile
Production-ready Kubernetes manifests: Deployment, Service, ConfigMap, Ingress, and HPA. The current v3.x releases intentionally focus on Docker Compose and systemd (bare-metal) distributions.

### 2. Performance benchmarks & load testing
Develop automated, reproducible load testing suites (k6 or Locust) measuring requests/second, p95/p99 latency overhead, and resource consumption comparing raw Caddy vs Caddy + Coraza WAF (PL1 through PL4).

### 3. Alpine 3.24 base image migration
The image runs on Alpine 3.23 (tied to official `caddy:2.11.4` base). Migrate to Alpine 3.24 once Caddy publishes official upstream images on it. Build-time `apk upgrade` keeps current packages patched.

### 4. mTLS remote administration
Enable Caddy's remote admin listener with mutual TLS (`admin.remote` on `:2021`) using local PKI CA and client certificate authentication for integration with `caddy-waf-ui`.

### 5. WAF rule hot-reload investigation
Evaluate dynamically reloading Coraza rules via Caddy's admin API without restarting the container or interrupting in-flight requests.

---

## 🌟 Community Adoption, Growth & User Feedback

Caddy-WAF is engineered as an open, production-grade security distribution. Expanding real-world adoption, community contributions, and active feedback loops is a core pillar of our roadmap:

* **Adoption & Community Growth**: Target active use cases across diverse production environments (homelabs, VPS, edge proxies, bare-metal clusters). Grow GitHub stars organically through demonstrable engineering quality, developer trust, and clear documentation.
* **Open Feedback Channel**: User feedback, architectural suggestions, edge-case reports, and false-positive findings are actively welcomed.
* **Direct Contact & Maintenance**:
  * **General feedback & questions**: [miguel@developmi.com](mailto:miguel@developmi.com)
  * **Vulnerabilities & security findings**: [security@developmi.com](mailto:security@developmi.com) or via [GitHub Security Advisories](https://github.com/Developmi/caddy-waf/security/advisories/new)
  * **GitHub Issues**: [github.com/developmi/caddy-waf/issues](https://github.com/developmi/caddy-waf/issues)
* **Response SLAs**: All incoming feedback and security reports receive strict follow-up according to [SECURITY.md](./SECURITY.md#response-timeline):
  * **Acknowledgment**: within **48 hours**.
  * **Initial assessment**: within **5 business days**.
  * **Resolution target**: **30 days** (critical security issues prioritized within **7 days**).
