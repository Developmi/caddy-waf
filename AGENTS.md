# caddy-waf

## Stack
- **Type**: Docker infrastructure / deployment (no Go source code)
- **Base image**: Caddy 2.11.4 (Alpine-based)
- **WAF Engine**: Coraza WAF 2.5.0 (via coraza-caddy plugin)
- **Rule Set**: OWASP CRS 4.28.0
- **Additional plugins**: caddy-ratelimit (0.1.0, pinned 5625512), caddy-dns/cloudflare (0.2.4)
- **Language**: Go (build-time only via xcaddy builder image)
- **Orchestration**: Docker Compose

## Commands
- **Run**: `docker compose up`
- **Test**: `make test-waf` (go-ftw integration suite) + `docker compose up` manual validation
- **Build**: `docker build -t caddy-waf .`
- **Validate**: `docker compose config`
- **Lint/Format**: N/A (no app source code)

## SDD Context
- **CodeGraph indexed**: yes
- **Graphify indexed**: yes (graphify-out/ present)
- **Testing framework**: go-ftw integration suite (tests/integration, run via `make test-waf`)
- **Strict TDD**: disabled - no test runner detected
- **Quality tools**: Trivy (container scanning) | Cosign (signing) | Syft (SBOM)

## Security Posture
- **License**: MIT - fully open source
- **Maintainer**: Miguel Lozano / Developmi
- **User**: Non-root caddy (UID 1337)
- **Hardening**: read_only rootfs, cap_drop ALL, no-new-privileges, tmpfs noexec
- **Supply chain**: Cosign keyless signing, Trivy CRITICAL/HIGH gate, SBOM attestations
- **SHA256 verification**: OWASP CRS tarball (v4.28.0) and coraza.conf (v3.7.0, via `CORAZA_CONF_SHA256` ARG) verified against pinned SHA256 checksums at build time
- **CVEs resolved**: CVE-2026-27590 (9.1), CVE-2026-27587 (9.1), CVE-2026-27588 (8.8), CVE-2026-30851 (8.8), CVE-2026-52845 (8.1), CVE-2026-27586 (7.5), CVE-2026-52844 (7.5), CVE-2026-27585 (6.5), CVE-2026-27589 (6.1)
- **Security validation rule**: always contrast the CURRENT date against registered security issues. Validate only OPEN/active advisories (`.trivyignore` entries, SECURITY.md pending sections, base image and dependency versions) — never historical/closed ones unless the user asks. Re-check open advisories on every session and whenever upstream versions move (e.g., pending HIGHs awaiting a newer Caddy release).

## CI/CD
- **Workflow**: `docker-build-scan-sign.yml` - scan → sign → push (multi-arch amd64+arm64, tag-triggered only)
- **Workflow**: `test-waf.yml` - functional gate: runs `make test-waf` (go-ftw, 4-case baseline) on every PR and push to main
- **Registry**: `ghcr.io/developmi/caddy-waf`
- **Triggers**: tags v* (releases) + PRs to main (validation)
- **Scan gate**: Trivy fails build on CRITICAL/HIGH (ignores unfixed)

## Conventions
- Commit style: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`)
- Versioning: Semantic Versioning (v3.3.2 current)
- Branch naming: `feat/desc`, `fix/desc`, `docs/desc`, `chore/desc`, `ci/desc`
- go-ftw integration tests via `make test-waf` (container starts on 127.0.0.1:9090) + manual validation
- WAF default: DetectionOnly (change to On after 7-14 day observation window)
- Observability profiles (not in default `up`): `docker compose --profile observability-vm up -d` (VictoriaMetrics + Grafana) | `--profile observability-prom up -d` (Prometheus + Grafana); both scrape the same metrics/prometheus.yml from caddy-waf:2019 — admin /metrics must stay internal-only (never publish 2019)

## Key Gotchas
- Caddyfile is runtime config mounted at `/etc/caddy/Caddyfile:ro`
- Environment variables drive site address and backend upstream
- Deployment modes: Docker Compose (default), systemd (bare-metal), Kubernetes (planned)
- `caddy-ratelimit` pinned by commit SHA (no version tags beyond v0.1.0)
- `caddy-dns/cloudflare` v0.2.4 fixes Cloudflare API token format (`cfut_`) - DO NOT use < v0.2.3 with new tokens

## Pre-Resolved Context (auto-populated by orchestrator)
This section is populated by the orchestrator before launching sub-agents.
