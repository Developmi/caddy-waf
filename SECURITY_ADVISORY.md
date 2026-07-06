# Security Advisory

## Advisory Overview

This document lists security vulnerabilities resolved in the caddy-waf image.  
All CVEs listed below are resolved in **v3.0.0** and later.

---

## CVE-2026-27590

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27590 |
| **CVSS** | **9.1 CRITICAL** |
| **Description** | Remote Code Execution via FastCGI Unicode encoding bypass. An attacker can execute arbitrary code when Caddy is configured as a reverse proxy to a FastCGI backend by sending a specially crafted request with Unicode-encoded path segments. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.2) |
| **Resolved In** | Caddy 2.11.2+ (included in caddy-waf v3.0.0) |

---

## CVE-2026-30851

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-30851 |
| **CVSS** | **8.8 HIGH** |
| **Description** | Authentication bypass via request smuggling in path matching. An attacker can bypass authentication on protected routes by exploiting inconsistent path parsing between Caddy's route matching and the upstream handler. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.1) |
| **Resolved In** | Caddy 2.11.1+ (included in caddy-waf v3.0.0) |

---

## CVE-2026-27587

| Field | Value |
|-------|-------|
| **CVE ID** | CVE-2026-27587 |
| **CVSS** | **9.1 CRITICAL** |
| **Description** | Path traversal via encoded URI. An attacker can access files outside the document root by submitting a crafted URI with encoded path traversal sequences that bypass Caddy's path normalization. |
| **Affected** | caddy-waf < 3.0.0 (Caddy < 2.11.2) |
| **Resolved In** | Caddy 2.11.2+ (included in caddy-waf v3.0.0) |

---

## Mitigation

Users running caddy-waf v2.0.x or earlier should upgrade to v3.0.0 immediately.

```bash
docker pull ghcr.io/developmi/caddy-waf:v3.0.0
```

For users unable to upgrade immediately, ensure Caddy is not deployed in a configuration that exposes FastCGI upstreams to untrusted networks, and review path-based access control rules for bypass vectors. These are temporary mitigations only — upgrading is the recommended action.

---

## Timeline

- **2026-05-28**: Caddy 2.11.2 released fixing CVE-2026-27590 and CVE-2026-27587
- **2026-06-03**: Caddy 2.11.4 released (latest stable)
- **2026-07-01**: caddy-waf v3.0.0 released with Caddy 2.11.4

---

## References

- [Caddy Release Notes](https://github.com/caddyserver/caddy/releases)
- [Caddy Security Policy](https://github.com/caddyserver/caddy/security/policy)
- [caddy-waf CHANGELOG](./CHANGELOG.md)
