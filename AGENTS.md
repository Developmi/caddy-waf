# caddy-waf

## Stack
- **Type**: Docker infrastructure / deployment (no Go source code)
- **Base image**: Caddy 2.11.4 (Alpine-based)
- **WAF Engine**: Coraza WAF 2.5.0 (via coraza-caddy plugin)
- **Rule Set**: OWASP CRS 4.28.0
- **Additional plugins**: caddy-ratelimit (0.1.0, pinned 5625512), caddy-dns/cloudflare (0.2.3)
- **Language**: Go (build-time only via xcaddy builder image)
- **Orchestration**: Docker Compose

## Commands
- **Run**: `docker compose up`
- **Test**: `docker compose up` + manual validation (no automated test framework)
- **Build**: `docker build -t caddy-waf .`
- **Validate**: `docker compose config`
- **Lint/Format**: N/A (no app source code)

## SDD Context
- **CodeGraph indexed**: yes
- **Graphify indexed**: yes (graphify-out/ present)
- **Testing framework**: none (manual validation only)
- **Strict TDD**: disabled — no test runner detected
- **Quality tools**: Trivy (container scanning) | Cosign (signing) | Syft (SBOM)

## Security Posture
- **License**: MIT — fully open source
- **Maintainer**: Miguel Lozano / Developmi
- **User**: Non-root caddy (UID 1337)
- **Hardening**: read_only rootfs, cap_drop ALL, no-new-privileges, tmpfs noexec
- **Supply chain**: Cosign keyless signing, Trivy CRITICAL/HIGH gate, SBOM attestations
- **⚠️ SHA256 verification**: placeholder `REPLACE_BEFORE_BUILD` in Dockerfile — not actually enforced
- **CVEs resolved**: CVE-2026-27590 (9.1), CVE-2026-30851 (8.8), CVE-2026-27587 (9.1)

## CI/CD
- **Primary**: `docker-build-scan-sign.yml` — scan → sign → push (multi-arch amd64+arm64)
- **Legacy**: `build-push.yml` — direct push on tags (no security checks)
- **Registry**: `ghcr.io/developmi/caddy-waf`
- **Triggers**: push to main, tags v*, PRs to main
- **Scan gate**: Trivy fails build on CRITICAL/HIGH (ignores unfixed)

## Conventions
- Commit style: Conventional Commits (`feat:`, `fix:`, `docs:`, `chore:`, `ci:`)
- Versioning: Semantic Versioning (v3.0.0 current)
- Branch naming: `feat/desc`, `fix/desc`, `docs/desc`, `chore/desc`, `ci/desc`
- No tests — manual validation via `docker compose up`
- WAF default: DetectionOnly (change to On after 7-14 day observation window)

## Key Gotchas
- Caddyfile is runtime config mounted at `/etc/caddy/Caddyfile:ro`
- Environment variables drive site address and backend upstream
- Deployment modes: Docker Compose (default), systemd (bare-metal), Kubernetes (planned)
- `caddy-ratelimit` pinned by commit SHA (no version tags beyond v0.1.0)
- CI runs duplicate builds on tag push (both workflows trigger) — ponytail: consolidate

## Pre-Resolved Context (auto-populated by orchestrator)
This section is populated by the orchestrator before launching sub-agents.
