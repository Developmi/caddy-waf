# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/)

## [3.2.0] - 2026-07-18

### Added

- **Lint workflow** (`.github/workflows/lint.yml`) — runs `yamllint`, `actionlint`, `hadolint`, and `zizmor` on PRs, main, and tags. All linters are blocking; failures prevent merge or release.

### Fixed

- **Trivy CI false positive**: scoped scan gate to vulnerability scanning only via `scanners: vuln`. Trivy v0.69.3+ enables secret scanning by default, which caused the pipeline to fail with exit code 1 even when no CRITICAL/HIGH vulnerabilities existed.

### Changed

- **aquasecurity/trivy-action**: upgraded from v0.35.0 to **v0.36.0**.
- **github/codeql-action/upload-sarif**: upgraded from v3 to **v4** (v3 deprecated December 2026).

## [3.1.0] - 2026-07-18

### Added

- Automated test suite with go-ftw (OWASP CRS framework). `make test` runs lint + WAF integration tests.
- Docker Compose test override (`docker-compose.test.yml`) - builds locally, runs on port 9090.
- `make doctor` now reports go-ftw version.

### Fixed

- Upgraded `c-ares`, `curl`, `libcurl` in base image (5 HIGH CVEs: CVE-2026-33630, CVE-2026-5773, CVE-2026-6276).

### Changed

- **caddy-dns/cloudflare**: upgraded from v0.2.3 to **v0.2.4** - fixes compatibility with Cloudflare API tokens using `cfut_` / `cfat_` prefix.
- Unified SECURITY.md (policy + resolved CVEs). Removed SECURITY_ADVISORY.md.
- Updated ROADMAP.md: moved completed items to ✅, added post-v3.0.0 priorities.
- Restricted CI workflow trigger: only `tags: [ 'v*' ]` for releases + PRs for validation.
- Updated README.md: removed broken SECURITY_ADVISORY references, aligned build-arg docs with Dockerfile defaults.
- Updated AGENTS.md: full CVEs list, removed legacy workflow refs, updated CI triggers.

## [3.0.0] - 2026-07-01

### Added

- **Caddy 2.11.4 upgrade** - resolves 9 CVEs including 2 CRITICAL (CVE-2026-27590, CVE-2026-27587) and CVE-2026-52845.
- **Coraza WAF v2.5.0** (from v2.2.0) - latest stable release.
- **OWASP CRS v4.28.0** (from v4.23.0) - latest rule set.
- **Coraza conf v3.7.0** (from v3.3.3) - latest recommended configuration.
- Cosign keyless signing and SBOM attestation (CycloneDX) in CI pipeline.
- Trivy vulnerability scanning with CRITICAL/HIGH severity gate.
- SLSA build provenance attestation via GitHub attest-build-provenance.
- Supply chain artifact entries in `.gitignore` and `.dockerignore`.
- Dev tooling: Makefile, uv, yamllint, zizmor, Go linters.
- Healthchecks at image level and compose level.
- Structured JSON logging configuration in Caddyfile templates.

### Changed

- **Dockerfile**:
  - Updated Caddy base image from `caddy:2.11` to `caddy:2.11.4`.
  - Updated Coraza WAF plugin from `v2.2.0` to `v2.5.0`.
  - Pinned Alpine package versions (`wget=1.25.0-r2`, `tar=1.35-r4`).
  - Updated Coraza configuration SHA256 checksum for v3.7.0.
  - Updated OWASP CRS SHA256 checksum for v4.28.0.
  - Fixed SHELL pipefail syntax (`-eo` → `-eo`).
- **docker-compose.yml**: User mapping, security options (no-new-privileges, cap_drop ALL), read_only rootfs, tmpfs, healthcheck.
- **Caddyfile.example**: Rewritten with production-ready examples (static site, reverse proxy, file server, PHP, WebSocket).
- **Caddyfile**: Enabled rate_limit plugin ordering and TLS protocol restrictions.
- **.env.example**: Added `CADDY_ADAPTER` with grouped category layout.
- **README.md**: Updated badges, versions, Cosign verification, and image reference to Developmi.
- **SECURITY.md**: Unified with SECURITY_ADVISORY.md. Updated supported versions (3.0.x only), added all 9 resolved CVEs, and expanded supply chain section.
- **ROADMAP.md**: Restructured with ✅ completed items from v3.0.0, current decisions, and pending priorities.
- **CONTRIBUTING.md**: Updated CI description for tag-based release workflow.
- Updated LICENSE copyright holder to `Miguel Lozano | Developmi`.
- Expanded `.gitignore` with Python/Node defensive entries and security/supply chain artifacts.
- All CI GitHub Actions pinned by commit SHA.
- Migrated from `Miguel-DevOps` organization to `Developmi` organization.

### Security

- **Caddy CVEs resolved** (via 2.11.4 upgrade):
  - CVE-2026-27590 - **9.1 CRITICAL** - RCE via FastCGI Unicode bypass
  - CVE-2026-27587 - **9.1 CRITICAL** - Path traversal via encoded URI
  - CVE-2026-27588 - **8.8 HIGH** - Host matcher case-sensitivity bypass
  - CVE-2026-30851 - **8.8 HIGH** - Auth bypass via request smuggling
  - CVE-2026-52845 - **8.1 HIGH** - forward_auth header injection via CGI underscore alias
  - CVE-2026-27586 - **7.5 HIGH** - TLS client auth fails open
  - CVE-2026-52844 - **7.5 HIGH** - Windows path bypass (N/A on Linux)
  - CVE-2026-27585 - **6.5 MEDIUM** - File matcher glob bypass
  - CVE-2026-27589 - **6.1 MEDIUM** - Admin no-cors request bypass
- **OWASP CRS not affected** (v4.28.0):
  - CVE-2026-21876 - **9.3 CRITICAL** - Fixed in CRS ≥ 4.22.0
  - CVE-2026-33691 - **6.8 MEDIUM** - Fixed in CRS ≥ 4.25.0

## [2.0.0] - 2026-03-14 - Made in deprecated repo

### Added

- Systemd service file for bare-metal deployments (`deploy/systemd/caddy-waf.service`).
- Example environment configuration file (`.env.example`).
- Security headers in Caddyfile.example: HSTS, X-Content-Type-Options, X-Frame-Options, Referrer-Policy.
- Structured JSON logging configuration in Caddyfile templates.
- TUNING.md with application-specific CRS exception guides (REST, GraphQL, Web apps).
- ROADMAP.md with planned supply chain, ratelimit fork, and compliance integrations.

### Changed

- **Dockerfile**: Pinned plugin versions via build args (Coraza WAF v2.2.0, caddy-ratelimit v0.1.0, caddy-dns/cloudflare v0.2.3).
- **Dockerfile**: SHA256 verification for OWASP CRS and Coraza configuration downloads.
- **Dockerfile**: Non-root execution with UID/GID 1337, read-only container, capability dropping, tmpfs hardening.
- **Dockerfile**: Multi-stage build with xcaddy builder and caddy:2.11 base images.
- **Dockerfile**: Caddy config validation step before final layer.
- **docker-compose.yml**: User mapping, security options (no-new-privileges, cap_drop ALL), read_only rootfs, tmpfs, healthcheck.
- **Caddyfile.example**: Rewritten with production-ready examples (static site, reverse proxy, file server, PHP, WebSocket).
- **Caddyfile**: Enabled rate_limit plugin ordering and TLS protocol restrictions.
- CI workflow updated for Ubuntu 24.04, multi-arch builds, and tag-based releases.
- Added container metadata labels (OCI standard).

### Fixed

- GitHub License badge link in README files.

## [1.0.0] - 2026-02-09 - Made in deprecated repo

### Added

- Initial release (Miguel-DevOps organization).
- Caddy 2.x with Coraza WAF and OWASP CRS v4.23.0.
- Dockerfile with Coraza WAF plugin integration.
- Docker Compose with example backend service.
- Basic Caddyfile configuration with DetectionOnly WAF mode.
- README.md and README.es.md with setup instructions.

<!-- Version links for Keep a Changelog -->
[3.2.0]: https://github.com/Developmi/caddy-waf/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/Developmi/caddy-waf/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/Developmi/caddy-waf/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/Miguel-DevOps/caddy-waf/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/Miguel-DevOps/caddy-waf/releases/tag/v1.0.0
