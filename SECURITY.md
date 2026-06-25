# Security policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 2.0.x   | ✅ Yes    |
| 1.0.x   | ❌ No     |

Only the latest release line receives security updates.
The image is rebuilt with updated base images and plugin versions on a regular cadence.

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately via one of these channels:
- **GitHub Security Advisories:** [Report a vulnerability](https://github.com/Miguel-DevOps/caddy-waf/security/advisories/new)
- **Email:** miguel@developmi.com — encrypt with PGP if the finding is critical.

Include in your report:
- Description of the vulnerability and its potential impact.
- Steps to reproduce or a proof-of-concept.
- Affected versions.
- Any suggested mitigations.

## Response timeline

| Stage | Target time |
|---|---|
| Acknowledgment | 48 hours |
| Initial assessment | 5 business days |
| Fix or mitigation | 30 days (critical: 7 days) |
| Public disclosure | After fix is available and users have had a reasonable window to upgrade |

## Disclosure policy

This project follows coordinated disclosure. We ask that you give us reasonable time to address the vulnerability before public disclosure. We will credit reporters in the release notes unless anonymity is requested.

## Supply chain

This project uses:
- **Pinned dependencies**: All Go plugins are pinned by version in the Dockerfile build args.
- **SHA256 verification**: OWASP CRS rules and Coraza configuration are checksum-verified before installation.
- **Signed images**: Container images published to GHCR are signed with Cosign (keyless OIDC). SBOM attestations are attached for every release.
- **Vulnerability scanning**: Every build is scanned with Trivy before pushing. CRITICAL and HIGH vulnerabilities block the pipeline.

Verify the image signature before pulling in production:

```bash
cosign verify \
  --certificate-identity "https://github.com/Miguel-DevOps/caddy-waf/.github/workflows/docker-build-scan-sign.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/miguel-devops/caddy-waf@sha256:<digest>
```
