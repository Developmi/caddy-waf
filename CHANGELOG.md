# Changelog

All notable changes to this project will be documented in this file.
Format: [Keep a Changelog](https://keepachangelog.com/) · Versioning: [SemVer](https://semver.org/)

## [Unreleased]

### Added
- Cosign keyless signing and SBOM attestation in CI pipeline.
- Trivy vulnerability scanning with CRITICAL/HIGH severity gate.
- Supply chain artifact entries in `.gitignore` and `.dockerignore`.

### Changed
- Updated LICENSE copyright holder to `Miguel Lozano | Developmi`.
- Added `CADDY_ADAPTER` to `.env.example` with grouped category layout.
- Expanded `.gitignore` with Python/Node defensive entries and security/supply chain artifacts.

## [2.0.0] — 2026-03-14

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

## [1.0.0] — 2026-02-09

### Added
- Initial release. Caddy 2.x with Coraza WAF and OWASP CRS v4.23.0.
- Dockerfile with Coraza WAF plugin integration.
- Docker Compose with example backend service.
- Basic Caddyfile configuration with DetectionOnly WAF mode.
- README.md and README.es.md with setup instructions.
