# SOC 2 control mappings

Mapping of SOC 2 Trust Services Criteria (TSC) categories to what caddy-waf
**actually implements**, with file:line evidence for every claim. This is a
deployment-level mapping: the application behind the WAF has its own controls
and is not covered here.

Rows marked *documented elsewhere* or *not implemented* are honest gaps — the
project does not claim controls it does not have.

## CC6 — Security configuration & logical access

| Requirement | Implementation | Evidence |
|-------------|----------------|----------|
| Restrict access to systems and data | Container runs as non-root `1337:1337`, drops all capabilities except `NET_BIND_SERVICE`, `no-new-privileges`, read-only rootfs, tmpfs mounted `noexec` | docker-compose.yml:8-21 |
| Apply least privilege to the host process (bare-metal) | systemd unit runs as dedicated `caddy-waf` user with `AmbientCapabilities=CAP_NET_BIND_SERVICE` only, `NoNewPrivileges=true`, `ProtectSystem=strict`, `PrivateTmp`, syscall filtering | deploy/systemd/caddy-waf.service:8-18,25-40 |
| Prevent unauthorized exposure of management interfaces | Caddy admin API (`:2019`, serves `/metrics`) is bound inside the internal Docker network only — never published to the host; Grafana bound to loopback | Caddyfile.example:16-20; docker-compose.yml:22-25,141,167 |
| Secure configuration of security components | WAF defaults to `SecRuleEngine DetectionOnly` — new deployments observe before enforcing, reducing the blast radius of misconfiguration | Caddyfile.example:56 |

## CC7 — Monitoring, detection & incident response

| Requirement | Implementation | Evidence |
|-------------|----------------|----------|
| Detect anomalous activity | Structured JSON access + WAF audit logs to stdout (Coraza audit log carries `waf_rule_id` / decision); `caddy_http_*` Prometheus metrics on the admin endpoint | Caddyfile.example:25-31,60-62; README.md:319-347 |
| Collect and store metrics | Dual-backend observability (VictoriaMetrics or Prometheus) scraping the same `metrics/prometheus.yml`; Grafana dashboard with request rate, status codes, p95 latency, backend health | docker-compose.yml:62-172; metrics/prometheus.yml; grafana/dashboards/caddy-waf.json |
| Monitor service health | Healthcheck probes the admin `/metrics` endpoint every 30s (process + API check) | docker-compose.yml:40-45 |
| Respond to identified incidents | Dedicated IR runbook for WAF false positives: triage, rule exclusion, DetectionOnly fallback, severity table | docs/incident-response.md |
| *Limitation — WAF-specific metrics* | coraza-caddy v2.5.0 exports **no** `coraza_waf_*` metrics (upstream limitation). WAF visibility comes from `caddy_http_*` series, the WAF-mode panel in the dashboard, and the JSON audit log. Tracked as a future upstream-watch item, not a regression | README.md:345-347 |

## CC8 — Change management

| Requirement | Implementation | Evidence |
|-------------|----------------|----------|
| Changes are authorized and tested before release | PRs to `main` run the lint workflow (yamllint, hadolint, actionlint, zizmor); integration suite `make test-waf` (4 go-ftw cases) validates WAF behavior; container scans gate CRITICAL/HIGH before push | lint.yml:4-5,41-52; Makefile:103-104; tests/integration/baseline.yaml; .github/workflows/docker-build-scan-sign.yml:100-115 |
| Releases are intentional and auditable | Pushes to the registry happen **only** on `v*` tags; multi-arch build, SBOM, Cosign keyless signature and attestation, SLSA provenance all tied to the tag event | .github/workflows/docker-build-scan-sign.yml:5,98-149 |
| Dependencies are tracked and updated | Dependabot config for Docker + GitHub Actions | .github/dependabot.yml (commit 87c7c93) |
| Changes are documented | Deployment checklists per environment, tuning guide, changelog, this mapping | docs/deployment-checklist.md; TUNING.md; CHANGELOG.md |

## Supply chain integrity (supports CC6/CC8)

| Requirement | Implementation | Evidence |
|-------------|----------------|----------|
| Verify integrity of downloaded components | OWASP CRS v4.28.0 tarball and `coraza.conf` are SHA256-checked at build time (`CORAZA_CONF_SHA256` ARG) | Dockerfile:43,50-52,58-59 |
| Pin versions of system packages | Alpine `wget`, `tar` pinned by exact version | Dockerfile:48 |
| Pin third-party actions | All GitHub Actions pinned by commit SHA with `# vX` comments | .github/workflows/docker-build-scan-sign.yml:25-47; lint.yml:17-19,23 |
| Attest and sign artifacts | Cosign keyless signing (OIDC) + SBOM (CycloneDX) attestation + SLSA build provenance attached to every tagged release | .github/workflows/docker-build-scan-sign.yml:111-149; SECURITY.md:50-71 |

## Not yet implemented / documented elsewhere

| Gap | Status |
|-----|--------|
| Formal access review process (user/role recertification) | **Not implemented** — single-maintainer project; no IAM surface |
| Backup / disaster recovery procedure for `caddy_data` volumes and `/var/lib/caddy-waf` | **Not implemented** — restore relies on re-issuance/backup you manage |
| Formal change approval beyond CI (second reviewer) | **Not implemented** — single maintainer |
| Audit log retention policy | **Partial** — json-file rotation 50m × 5 (docker-compose.yml:46-50); forward logs to your SIEM for retention |
| WAF decision metrics on `/metrics` | **Not implemented** — upstream coraza-caddy limitation; see CC7 |
| Threat model document | **Documented elsewhere** — controls, CVEs and disclosure in SECURITY.md:75-228 |
| Observability always-on | **Partial** — observability is an opt-in compose profile; enable in production |
