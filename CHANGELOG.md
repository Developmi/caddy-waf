# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/)

## [3.3.1] - 2026-08-11

### Added

- **docker-compose.yml**: resource limits for `caddy-waf` (`mem_limit: 512m`, `cpus: 1.0`).
- **docker-compose.yml**: JSON-file log rotation (`max-size: 50m`, `max-file: 5`).

### Changed

- **Dockerfile**: HEALTHCHECK now checks the Caddy admin `/metrics` endpoint (`curl -fs http://127.0.0.1:2019/metrics`) instead of process-only `pgrep` — also detects hung processes and verifies the admin API responds. `curl` is used because busybox `wget` resolves `localhost` to `::1` and fails.
- **docker-compose.yml**: healthcheck mirrored to the same `/metrics` check (Compose healthcheck overrides the image's).
- **Version alignment**: OCI `LABEL version`, Compose default image tag, `pyproject.toml`/`uv.lock`, AGENTS.md, README.md, and SECURITY.md aligned to **v3.3.1**.

### Known issues (waiting on Caddy ≥ 2.11.5)

- **`CVE-2026-46600`** — golang.org/x/net v0.55.0 (embedded in the Caddy 2.11.4 binary), DoS via invalid DNS record parsing (`dns/dnsmessage`; fixed in x/net v0.56.0). Identified by the CI Trivy gate on 2026-08-14; tracked in `.trivyignore` until a patched Caddy release exists.
  - **Impact**: low for this deployment — DoS-class only; Caddy core and the `caddy-dns/cloudflare` module do not parse raw DNS wire messages here.
  - **Action**: remove the entry from `.trivyignore` and upgrade the base image to Caddy ≥ 2.11.5 as soon as it ships (also resolves `CVE-2026-56852` and `GHSA-hrxh-6v49-42gf`). Also tracked in SECURITY.md → Pending advisories.

## [3.3.0] - 2026-08-11

### Changed

- **hadolint**: upgraded from 2.14.0 to **2.15.1** (local tooling and `lint.yml`).
- **go-ftw**: upgraded from 2.4.0 to **2.5.0**.
- **Trivy**: upgraded from v0.72.0 to **v0.73.0** in CI (`setup-trivy` action remains SHA-pinned at v0.3.1).
- **Dockerfile**: widened `apk upgrade` from `c-ares curl libcurl` to **all packages** — pulls current Alpine 3.23 security fixes (openssl/libssl 3.5.7, curl 8.20.0, zlib 1.3.2, busybox, musl, ca-certificates) on every rebuild.
- **Dockerfile**: HEALTHCHECK converted to JSON form (`CMD ["pgrep", "caddy"]`) — required by hadolint 2.15.x rule DL3025.
- **Version alignment**: OCI `LABEL version`, Compose default image tag, `pyproject.toml`/`uv.lock`, AGENTS.md, README.md, and SECURITY.md aligned to **v3.3.0**.
- **AGENTS.md**: fixed stale notes (caddy-dns/cloudflare v0.2.4, real SHA256 checksums in Dockerfile, test suite documentation).

### Security

- **Full base-image package upgrade**: now covers OpenSSL/libssl and all Alpine 3.23 packages, not only curl/c-ares. Includes fixes for the June 2026 OpenSSL advisories and zlib CVE-2026-22184 (fixed in zlib 1.3.2-r0).

### Known issues (waiting on Caddy ≥ 2.11.5)

- **Two HIGH findings in the Caddy 2.11.4 binary**, tracked in `.trivyignore` until a patched Caddy release exists:
  - `CVE-2026-56852` — golang.org/x/text v0.37.0, DoS via invalid UTF-8 (fixed in x/text v0.39.0).
  - `GHSA-hrxh-6v49-42gf` — google.golang.org/grpc v1.81.0, xDS RBAC + HTTP/2 (fixed in grpc v1.82.1).
  - **Impact**: low for this deployment (DoS-class only, gRPC/xDS not used by Caddy core here; reverse-proxy only).
  - **Action**: remove both entries from `.trivyignore` and upgrade the base image to Caddy ≥ 2.11.5 as soon as it ships. Also tracked in SECURITY.md → Pending advisories.

## [3.2.1] - 2026-07-18

### Fixed

- **Trivy CI gate regression**: split the single combined command into two separate steps (SARIF upload + CRITICAL/HIGH exit-code gate). The combined command broke with trivy-action v0.70.0+.

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
[3.3.1]: https://github.com/Developmi/caddy-waf/compare/v3.3.0...v3.3.1
[3.3.0]: https://github.com/Developmi/caddy-waf/compare/v3.2.1...v3.3.0
[3.2.1]: https://github.com/Developmi/caddy-waf/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/Developmi/caddy-waf/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/Developmi/caddy-waf/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/Developmi/caddy-waf/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/Miguel-DevOps/caddy-waf/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/Miguel-DevOps/caddy-waf/releases/tag/v1.0.0
