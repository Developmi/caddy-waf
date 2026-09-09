# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/)

## [3.5.2] - 2026-09-09

### Release note

- **v3.5.0 and v3.5.1 were never published**: their tags were burned before any image was pushed — v3.5.0 by a 20-minute CI job timeout (raised to 45m in #27), v3.5.1 by the Trivy gate revealing new advisory **CVE-2026-84445** (grpc v1.82.1) at scan time. The `protect-tags-v` ruleset prevents deleting or rewriting those tags, so this identical image content ships as **v3.5.2** with the new finding suppressed.

### Changed

- **coraza-caddy**: upgraded from v2.5.0 to **v2.6.0** (`CORAZA_CADDY_REF`) — WebSocket+WAF fixes (#262), client IP logging (#321), `tx_id_req_header` support (#248), WriteHeader handling (#330), HPACK docs (#329), grpc dependency lifted to v1.82.1 (#340). WAF engine coraza/v3 stays **v3.7.0** and OWASP CRS stays **v4.29.0** — engine, rule-set, and Caddyfile configuration unchanged.
- **Dockerfile**: base image stages digest-pinned to their multi-arch index digests (2.11.4 tag kept as comment for readability):
  - builder: `caddy:2.11.4-builder@sha256:b8f9c720f13f64c13dd42db28e8f38a3fab54c11fce4d93bda26d710c448dcfd`
  - final: `caddy:2.11.4@sha256:df7f1c2fb114453b951de51a98efc010db1655a92c2e86be6706714e2417a78d`
- **Version alignment**: OCI `LABEL version` → **3.5.2** and `LABEL waf.coraza.version` → **2.6.0**.
- **Security**: new pending advisory `CVE-2026-84445` (grpc v1.82.1, xDS DoS, not reachable) added to `.trivyignore` and SECURITY.md — two HIGH suppressions now tracked until Caddy ≥ 2.11.5.

### Known issues (waiting on Caddy ≥ 2.11.5)

- **grpc-lift confirmed, two HIGH pending**: coraza-caddy v2.6.0's go.mod lifts `google.golang.org/grpc` to **v1.82.1** (verified in the shipped binary). Trivy cleared `GHSA-hrxh-6v49-42gf`, `CVE-2026-56852`, `CVE-2026-46600`, and `CVE-2026-56854`; `.trivyignore`/SECURITY.md were pruned accordingly. `CVE-2026-84304` (fixed in v1.83.1) and `CVE-2026-84445` (fixed in v1.82.2/v1.83.2) remain pending HIGHs until a later coraza-caddy/Caddy base ships grpc ≥ v1.82.2.

## [3.4.0] - 2026-08-24

### Changed

- **OWASP CRS**: upgraded from 4.28.0 to **4.29.0** — anti-evasion improvements for rule 932 (backslash-prefix and quote evasion in shell commands), `stat` command detection at PL-2+, expanded web shell detection, and false-positive fixes (942190/942200/942390/953100; 930120 restores `node_modules` coverage; 932171 allows `json.` prefix). Tarball SHA256 pinned: `cedd55533de917b6e397352a67a31993da4c07816f1fefcc94eacf542fc86337`.
- **CI**: Trivy upgraded from v0.73.0 to **v0.74.0** (setup-trivy action remains SHA-pinned).
- **CI**: Actions bumps from dependabot PRs #11-#15 — `actions/checkout` 4.3.1→7.0.1, `actions/upload-artifact` 4.6.2→7.0.1, `docker/setup-buildx-action` 3.12.0→4.2.0, `sigstore/cosign-installer` bump, `actions/attest-build-provenance` bump.
- **Version alignment**: OCI `LABEL version`, Compose default image tag, `.env.example`, `pyproject.toml`/`uv.lock`, AGENTS.md, README.md, SECURITY.md, and bug report template aligned to **v3.4.0**.

### Added

- **Tests**: integration suite expanded from 4 to **20 go-ftw cases** covering OWASP Top 10 2025 — baseline (4) + OWASP CRS core (10: SQLi, XSS, MSSQL, RCE, PHP exec, RFI/SSRF, LFI, header injection, unicode XSS) + bypass (6: false-positive check, double-encoding, header-based payloads, POST JSON body, fullwidth XSS). Documented across AGENTS.md, ROADMAP.md, README.md, CONTRIBUTING.md, PR template, and incident-response runbook.
- **docs**: SECURITY.md documents 5 additional resolved advisories (CVE-2026-45135, CVE-2026-30852, CVE-2026-45692, CVE-2026-52846, GHSA-j8px-rmrx-76h9) plus a "Caddy advisories - not applicable" section; CVE-2026-27590 corrected to fixed-in 2.11.1; ROADMAP.md corrected Alpine 3.23 EOL (2027-11-01) and verified coraza version alignment (plugin v2.5.0 = engine v3.7.0).

### Known issues (waiting on Caddy ≥ 2.11.5)

- Unchanged from 3.3.2 — `CVE-2026-56852`, `GHSA-hrxh-6v49-42gf`, `CVE-2026-46600` (tracked in `.trivyignore`) and `GHSA-6365-7ppr-5r92` (Moderate, documented in SECURITY.md).

## [3.3.2] - 2026-08-14

### Added

- **Dockerfile**: WAF is now **active by default** in the baked config — `coraza_waf` runs first (`order coraza_waf first`), `SecRuleEngine DetectionOnly`, `SecAuditEngine RelevantOnly`, JSON audit log to `/data/logs/coraza-audit.log`, and a build-time grep gate fails the image if the WAF directives are missing.
- **Dockerfile**: `/data/logs` is created and owned by UID 1337 so Coraza can write the audit log at runtime (contract §7/D6).
- **CI**: dual-architecture Trivy scan (amd64 + arm64) with SARIF upload and CRITICAL/HIGH exit-code gate on both architectures.
- **Tests**: new bare-boot regression gate `make test-boot` (`tools/test-boot.sh`) — asserts the image starts healthy with the baked default config as UID 1337 (no mounts).
- **deploy/systemd**: tracked `Caddyfile.systemd` zero-trust variant (admin API bound to loopback only).
- **.env.example**: image pinned to `:v3.3.2` (no `:latest`); removed obsolete `CADDY_ADAPTER`.

### Fixed

- **Dockerfile**: baked default config could not boot as UID 1337 — `caddy validate` at build time (root) made Coraza create `/data/logs/coraza-audit.log` as root; the file is now re-chowned (`chown -R 1337:1337 /data/logs`) right after validation.
- **docs**: corrected `Caddyfile.systemd` admin citation in `docs/deployment-checklist.md` (lines 21-25).

### Changed

- **Version alignment**: OCI `LABEL version`, Compose default image tag, `.env.example`, `pyproject.toml`/`uv.lock`, AGENTS.md, README.md, SECURITY.md, and bug report template aligned to **v3.3.2**.
- **Known issues (waiting on Caddy ≥ 2.11.5)**: unchanged from 3.3.1 — `CVE-2026-56852`, `GHSA-hrxh-6v49-42gf`, `CVE-2026-46600` (tracked in `.trivyignore`) and `GHSA-6365-7ppr-5r92` (Moderate, documented in SECURITY.md).

## [3.3.1] - 2026-08-11

### Added

- **docker-compose.yml**: resource limits for `caddy-waf` (`mem_limit: 512m`, `cpus: 1.0`).
- **docker-compose.yml**: JSON-file log rotation (`max-size: 50m`, `max-file: 5`).

### Changed

- **Dockerfile**: HEALTHCHECK now checks the Caddy admin `/metrics` endpoint (`curl -fs http://127.0.0.1:2019/metrics`) instead of process-only `pgrep` — also detects hung processes and verifies the admin API responds. `curl` is used because busybox `wget` resolves `localhost` to `::1` and fails.
- **docker-compose.yml**: healthcheck mirrored to the same `/metrics` check (Compose healthcheck overrides the image's).
- **Version alignment**: OCI `LABEL version`, Compose default image tag, `pyproject.toml`/`uv.lock`, AGENTS.md, README.md, and SECURITY.md aligned to **v3.3.1**.

### Known issues (waiting on Caddy ≥ 2.11.5)

- **`CVE-2026-46600`** — golang.org/x/net v0.55.0 (embedded in the Caddy 2.11.4 binary), DoS via invalid DNS record parsing (`dns/dnsmessage`; fixed in x/net v0.56.0). Tracked in `.trivyignore` until a patched Caddy release exists (the finding was identified by the CI Trivy gate on 2026-08-14, after this release).
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

- Upgraded `c-ares`, `curl`, `libcurl` in base image (3 HIGH CVEs: CVE-2026-33630, CVE-2026-5773, CVE-2026-6276).

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
[3.5.2]: https://github.com/Developmi/caddy-waf/compare/v3.4.0...v3.5.2
[3.4.0]: https://github.com/Developmi/caddy-waf/compare/v3.3.2...v3.4.0
[3.3.1]: https://github.com/Developmi/caddy-waf/compare/v3.3.0...v3.3.1
[3.3.2]: https://github.com/Developmi/caddy-waf/compare/v3.3.1...v3.3.2
[3.3.0]: https://github.com/Developmi/caddy-waf/compare/v3.2.1...v3.3.0
[3.2.1]: https://github.com/Developmi/caddy-waf/compare/v3.2.0...v3.2.1
[3.2.0]: https://github.com/Developmi/caddy-waf/compare/v3.1.0...v3.2.0
[3.1.0]: https://github.com/Developmi/caddy-waf/compare/v3.0.0...v3.1.0
[3.0.0]: https://github.com/Developmi/caddy-waf/compare/v2.0.0...v3.0.0
[2.0.0]: https://github.com/Miguel-DevOps/caddy-waf/compare/v1.0.0...v2.0.0
[1.0.0]: https://github.com/Miguel-DevOps/caddy-waf/releases/tag/v1.0.0
