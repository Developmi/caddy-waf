# Security policy

## Supported versions

| Version | Supported |
|---------|-----------|
| 3.0.x   | ✅ Yes (current) |
| 2.0.x   | ❌ No - migrated to Developmi, upgrade to 3.0.x |
| 1.0.x   | ❌ No |

Only the latest release line receives security updates.

---

## Reporting a vulnerability

**Do not open a public GitHub issue for security vulnerabilities.**

Report vulnerabilities privately via one of these channels:

- **GitHub Security Advisories:** [Report a vulnerability](https://github.com/Developmi/caddy-waf/security/advisories/new)
- **Email:** security@developmi.com - encrypt with PGP if the finding is critical.

Include in your report:

- Description of the vulnerability and its potential impact.
- Steps to reproduce or a proof-of-concept.
- Affected versions.
- Any suggested mitigations.

---

## Response timeline

| Stage | Target time |
|-------|-------------|
| Acknowledgment | 48 hours |
| Initial assessment | 5 business days |
| Fix or mitigation | 30 days (critical: 7 days) |
| Public disclosure | After fix is available and users have had a reasonable window to upgrade |

---

## Disclosure policy

This project follows **coordinated disclosure**. We ask that you give us reasonable time to address the vulnerability before public disclosure. We will credit reporters in the release notes unless anonymity is requested.

---

## Supply chain

This project uses:

- **Pinned dependencies**: All Go plugins are pinned by version in the Dockerfile build args.
- **SHA256 verification**: OWASP CRS rules and Coraza configuration are checksum-verified before installation.
- **Pin apk versions**: Alpine packages (wget, tar) pinned by version.
- **Signed images**: Container images published to GHCR are signed with Cosign (keyless OIDC). SBOM attestations are attached for every release.
- **Vulnerability scanning**: Every build is scanned with Trivy before pushing. CRITICAL and HIGH vulnerabilities block the pipeline.
- **SLSA provenance**: Build provenance attested via GitHub's attest-build-provenance action.
- **Multi-arch**: Images built for `linux/amd64` and `linux/arm64`.

Verify the image signature before pulling in production:

```bash
cosign verify \
  --certificate-identity "https://github.com/Developmi/caddy-waf/.github/workflows/docker-build-scan-sign.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/developmi/caddy-waf@sha256:<digest>
```

> **Tip:** Use immutable image digests (`@sha256:...`) instead of version tags in production for deterministic deployments.

---

## Resolved CVEs

All CVEs listed below are resolved in **caddy-waf v3.0.0** (Caddy ≥ 2.11.4) and later.

### CVE-2026-27590

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27590 |
| **CVSS** | **9.1 CRITICAL** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N |
| **CWE** | CWE-172 (Encoding Error) |
| **Description** | Remote Code Execution via FastCGI Unicode encoding bypass. An attacker can execute arbitrary code when Caddy is configured as a reverse proxy to a FastCGI backend by sending a specially crafted request with Unicode-encoded path segments. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.2) |
| **Resolved In** | Caddy 2.11.2+ (included in caddy-waf v3.0.0) |

### CVE-2026-27587

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27587 |
| **CVSS** | **9.1 CRITICAL** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N |
| **CWE** | CWE-22 (Path Traversal) |
| **Description** | Path traversal via encoded URI. An attacker can access files outside the document root by submitting a crafted URI with encoded path traversal sequences that bypass Caddy's path normalization. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.2) |
| **Resolved In** | Caddy 2.11.2+ (included in caddy-waf v3.0.0) |

### CVE-2026-27588

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27588 |
| **CVSS** | **8.8 HIGH** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N |
| **CWE** | CWE-178 (Case Sensitivity) |
| **Description** | The Host matcher becomes case-sensitive for large host lists (>100 entries), enabling host-based route/auth bypass. An attacker can use a case-variant Host header to reach routes that should be protected. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.3) |
| **Resolved In** | Caddy 2.11.3+ (included in caddy-waf v3.0.0) |

### CVE-2026-30851

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-30851 |
| **CVSS** | **8.8 HIGH** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:H/A:N |
| **CWE** | CWE-444 (Inconsistent Interpretation) |
| **Description** | Authentication bypass via request smuggling in path matching. An attacker can bypass authentication on protected routes by exploiting inconsistent path parsing between Caddy's route matching and the upstream handler. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.1) |
| **Resolved In** | Caddy 2.11.1+ (included in caddy-waf v3.0.0) |

### CVE-2026-52845

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-52845 |
| **CVSS** | **8.1 HIGH** |
| **Vector** | AV:N/AC:L/PR:L/UI:N/S:U/C:H/I:H/A:N |
| **CWE** | CWE-287 + CWE-290 + CWE-444 |
| **Description** | `forward_auth copy_headers` deletes the exact client-supplied identity header before copying the trusted value from the auth gateway. When the request goes through php_fastcgi, Caddy normalizes headers into CGI variables (replacing `-` with `_`). An underscore alias survives the delete step and becomes the same PHP/FastCGI variable, allowing a client to inject or override identity/group headers. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.4) |
| **Resolved In** | Caddy 2.11.4+ (included in caddy-waf v3.0.0) |

### CVE-2026-27586

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27586 |
| **CVSS** | **7.5 HIGH** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:N/I:H/A:N |
| **CWE** | CWE-295 (Certificate Validation) |
| **Description** | TLS client authentication silently fails open when the CA certificate file is missing or malformed. Connections from clients without a valid certificate are accepted when they should be rejected. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.3) |
| **Resolved In** | Caddy 2.11.3+ (included in caddy-waf v3.0.0) |

### CVE-2026-52844

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-52844 |
| **CVSS** | **7.5 HIGH** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:H/I:N/A:N |
| **CWE** | CWE-22 (Path Traversal) |
| **Description** | On Windows only: Caddy path matchers treat `/private\secret.txt` as outside `/private/`, but `file_server` resolves the same request path as `private\secret.txt` on disk. An unauthenticated remote client can bypass Caddy path-scoped auth/deny routes. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.4) on **Windows** only |
| **Resolved In** | Caddy 2.11.4+ (included in caddy-waf v3.0.0) |
| **Note** | Linux/container deployments are **not affected**. Documented for transparency. |

### CVE-2026-27585

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27585 |
| **CVSS** | **6.5 MEDIUM** |
| **Vector** | AV:N/AC:L/PR:N/UI:N/S:U/C:L/I:L/A:N |
| **CWE** | CWE-20 (Improper Input Validation) |
| **Description** | Improper sanitization of glob characters in the file matcher may lead to bypassing path-based security protections. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.3) |
| **Resolved In** | Caddy 2.11.3+ (included in caddy-waf v3.0.0) |

### CVE-2026-27589

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27589 |
| **CVSS** | **6.1 MEDIUM** |
| **Vector** | AV:L/AC:L/PR:N/UI:R/S:C/C:L/I:L/A:L |
| **CWE** | CWE-942 (CORS) |
| **Description** | Cross-origin requests attempted with `no-cors` mode could cause some API requests to succeed. (Requires a malicious web page running locally to the production Caddy process.) |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.3) |
| **Resolved In** | Caddy 2.11.3+ (included in caddy-waf v3.0.0) |

### OWASP CRS - not affected

The following CVEs affect older OWASP CRS versions. **caddy-waf v3.0.0 ships CRS v4.28.0 and is not affected.** Listed for transparency.

| CVE | CVSS | Fixed In | Description |
|-----|------|----------|-------------|
| CVE-2026-21876 | **9.3 CRITICAL** | CRS ≥ 4.22.0 | Multipart charset bypass in rule 922110 |
| CVE-2026-33691 | **6.8 MEDIUM** | CRS ≥ 4.25.0 | File upload bypass with whitespace padding |

---

## Timeline

| Date | Event |
|------|-------|
| **2026-02-09** | Caddy 2.11.1 released - fixes CVE-2026-30851 |
| **2026-02-24** | Caddy 2.11.2 released - fixes CVE-2026-27590, CVE-2026-27587 |
| **2026-05-12** | Caddy 2.11.3 released - fixes CVE-2026-27588, CVE-2026-27586, CVE-2026-27585, CVE-2026-27589 |
| **2026-06-02** | Caddy 2.11.4 released - fixes CVE-2026-52845, CVE-2026-52844 |
| **2026-06-23** | CVE-2026-52845 and CVE-2026-52844 published to NVD |
| **2026-07-01** | caddy-waf **v3.0.0** released with Caddy 2.11.4 |
| **2026-07-02** | OWASP CRS v4.28.0 released (included) |

---

## References

- [Caddy Release Notes](https://github.com/caddyserver/caddy/releases)
- [Caddy Security Policy](https://github.com/caddyserver/caddy/security/policy)
- [caddy-waf CHANGELOG](./CHANGELOG.md)
- [Coraza WAF Security](https://github.com/corazawaf/coraza/security)
- [OWASP CRS Advisories](https://github.com/coreruleset/coreruleset/security)
- [NVD: Caddy CVEs](https://nvd.nist.gov/vuln/search/results?query=caddy&search_type=all)
