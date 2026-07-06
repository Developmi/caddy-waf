# Roadmap

## Current decisions

- No hard blockers in default compose flow.
- WAF default mode is `DetectionOnly`.
- Transition to `SecRuleEngine On` is required only after a prudent production observation window.
- Runtime values are environment-driven (`SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL`, `CADDY_WAF_IMAGE`, `EXAMPLE_APP_IMAGE`).
- Healthchecks are present at image level and compose level.
- All Caddy plugins use official upstream modules. Rate limiting uses `mholt/caddy-ratelimit`, DNS challenge support uses `caddy-dns/cloudflare`, and security headers use Caddy's native `header` directive.

## CVE remediation

v3.0.0 upgrades Caddy to **2.11.4**, which resolves the following critical and high-severity vulnerabilities:

| CVE | CVSS | Description | Resolved In |
|-----|------|-------------|-------------|
| CVE-2026-27590 | **9.1** CRITICAL | RCE via FastCGI Unicode encoding bypass — allows remote code execution when Caddy is configured as reverse proxy to FastCGI | Caddy 2.11.2+ |
| CVE-2026-30851 | **8.8** HIGH | Authentication bypass via request smuggling in path matching — attacker can bypass authentication on protected routes | Caddy 2.11.1+ |
| CVE-2026-27587 | **9.1** CRITICAL | Path traversal via encoded URI — allows access to files outside the document root | Caddy 2.11.2+ |

All three CVEs are resolved in v3.0.0 via the Caddy 2.11.4 upgrade. Users on v2.0.x or earlier should upgrade immediately.

## Required production rollout sequence

1. Deploy with `DetectionOnly`.
2. Observe and tune for false positives.
3. Move to `SecRuleEngine On` after baseline confidence.
4. Keep monitoring and refine CRS exclusions per application behavior.

## Plugin suite

- All Caddy plugins use official upstream modules. Rate limiting uses `mholt/caddy-ratelimit`, DNS challenge support uses `caddy-dns/cloudflare`, and security headers use Caddy's native `header` directive.

These plugins are pinned by version tag and built into the image via xcaddy at Docker build time.

## Planned future integrations

### 1. Supply chain hardening

- Pin GitHub Actions by commit SHA.
- Add SBOM generation and artifact signing.
- Enforce vulnerability gates in CI.
- Add Cosign attestation verification to build pipeline.
- Integrate Dependabot or Renovate for automated dependency updates across plugin dependencies.

### 2. Runtime hardening improvements

- Add optional trusted proxy profile examples.
- Add HTTP/3 host kernel tuning guidance.
- Add deployment profiles for Docker, systemd, and Kubernetes.
- Evaluate seccomp and AppArmor profiles for container runtime.
- Add WAF rule hot-reload without container restart.

### 3. Compliance and operations

- Add a formal deployment checklist per environment.
- Add incident response runbook for WAF false positives.
- Add periodic review cadence for plugin and base image updates.
- Document SOC2 control mappings for the WAF deployment.
- Add SLSA compliance documentation for the build pipeline.

### 4. Testing and observability

- Add regression tests for rate-limit behavior and bypass resistance.
- Add structured WAF metrics export for Prometheus.
- Add pre-built Grafana dashboard for WAF monitoring.
- Implement end-to-end FTW (Failure Tracking Web) test suite against the container image.
