# Roadmap

## Current decisions (public repository defaults)

- No hard blockers in default compose flow.
- WAF default mode is `DetectionOnly`.
- Transition to `SecRuleEngine On` is required only after a prudent production observation window.
- Runtime values are environment-driven (`SITE_ADDRESS`, `BACKEND_UPSTREAM`, `ACME_EMAIL`, `CADDY_WAF_IMAGE`, `EXAMPLE_APP_IMAGE`).
- Healthchecks are present at image level and compose level.

## Required production rollout sequence

1. Deploy with `DetectionOnly`.
2. Observe and tune for false positives.
3. Move to `SecRuleEngine On` after baseline confidence.
4. Keep monitoring and refine CRS exclusions per application behavior.

## Known constraints and non-blocking posture

- `mholt/caddy-ratelimit` currently pinned to `v0.1.0`.
- A custom fork with updated security posture is planned and should replace current source when ready.
- This is tracked as planned work and does not block current release.

## Planned future integrations

### 1. Custom ratelimit fork integration

- Replace upstream module source with maintained fork reference.
- Add release attestation and signed provenance for forked builds.
- Add regression tests for rate-limit behavior and bypass resistance.

### 2. Supply chain hardening

- Pin GitHub Actions by commit SHA.
- Add SBOM generation and artifact signing.
- Enforce vulnerability gates in CI.

### 3. Runtime hardening improvements

- Add optional trusted proxy profile examples.
- Add HTTP/3 host kernel tuning guidance.
- Add deployment profiles for Docker, systemd, and Kubernetes.

### 4. Compliance and operations

- Add a formal deployment checklist per environment.
- Add incident response runbook for WAF false positives.
- Add periodic review cadence for plugin and base image updates.
