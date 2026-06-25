<div align="center">

<img src="assets/caddy-waf.png" alt="Caddy WAF logo" width="120"/>

# Caddy WAF | Developmi

_Protect your web applications with enterprise-grade WAF in under 5 minutes — eliminate false-positive risk during deployment and slash SOC2 audit prep time._

[![Tech](https://img.shields.io/badge/Caddy_v2.11_|_Coraza_v2.2.0-green?style=for-the-badge&logo=caddy&logoColor=white)](https://caddyserver.com)
[![Docker](https://img.shields.io/badge/Docker_|_READY-2496ED?style=for-the-badge&logo=docker&logoColor=white)](https://hub.docker.com)
[![CI](https://img.shields.io/badge/CI-Passing-brightgreen?style=for-the-badge&logo=githubactions&logoColor=white)](https://github.com/Miguel-DevOps/caddy-waf/actions)
[![Supply Chain](https://img.shields.io/badge/Supply_Chain-Cosign_|_Trivy-4A90D9?style=for-the-badge)](https://github.com/Miguel-DevOps/caddy-waf/actions)
[![Status](https://img.shields.io/badge/Status-Production_Active-brightgreen?style=for-the-badge)](https://github.com/Miguel-DevOps/caddy-waf/pkgs/container/caddy-waf)
[![License](https://img.shields.io/badge/License-MIT_©_Miguel_Lozano_|_Developmi-blue?style=for-the-badge)](LICENSE)
[![OpenSSF Best Practices](https://img.shields.io/badge/OpenSSF-Best_Practices_In_Progress-orange?style=for-the-badge)](https://www.bestpractices.dev/en/criteria)

![Maintainer](https://img.shields.io/badge/Maintainer-Miguel_Lozano-black?style=for-the-badge)![Role](https://img.shields.io/badge/Cloud_&_Infrastructure_Engineer-333?style=for-the-badge)

> **Developmi Enterprise Edition** • Curated by [Miguel Lozano](https://developmi.com) • [GitHub](https://github.com/Miguel-DevOps) • [Container Registry](https://github.com/Miguel-DevOps/caddy-waf/pkgs/container/caddy-waf)

</div>

---

## Table of contents

- [Overview](#-overview)
- [Quick Start](#-quick-start)
- [Architecture](#-architecture)
- [Configuration Guide](#-configuration-guide)
- [Docker Deployment](#-docker-deployment)
- [Testing & Validation](#-testing--validation)
- [Monitoring & Observability](#-monitoring--observability)
- [Security](#-security)
- [Changelog](#-changelog)
- [Contributing](#-contributing)
- [License](#-license)
- [Contact & Support](#-contact--support)

---

## 🎯 Overview

**Problem:** Deploying a web application firewall typically requires weeks of tuning, dedicated appliances, and specialized security expertise. Most WAF solutions block legitimate traffic on day one, disrupting your users and forcing you to disable protections you just deployed.

**This project solves that.** It packages Caddy — the web server that automatically provisions TLS — with Coraza WAF and the OWASP Core Rule Set into a single hardened container. The WAF defaults to **DetectionOnly mode**, giving you a safe observation window before enforcement. You get 290+ protection rules covering SQL injection, XSS, command injection, and the entire OWASP Top 10 — without blocking a single legitimate request until you're ready.

### ✨ Features

#### 🔒 Security First
- **Non-root execution**: Runs as `caddy` user (UID 1337) — no root privileges
- **Supply chain security**: Pinned versions, SHA256 verification of OWASP CRS rules, Cosign-signed images, SBOM attestations
- **Multi-stage builds**: Minimal attack surface, optimized layers
- **Health monitoring**: Process verification healthcheck at both image and compose level
- **Structured logging**: JSON logs for SIEM integration

#### 🛡️ WAF Capabilities
- **Coraza WAF v2.2.0**: Modern, high-performance web application firewall engine
- **OWASP CRS v4.23.0**: Latest Core Rule Set with 290+ protection rules
- **DetectionOnly by default**: Prevents false positives in new deployments
- **Audit logging**: JSON audit logs to stdout for easy monitoring
- **Rate limiting**: Built-in rate limiting plugin for DDoS protection

#### 🚀 Production Ready
- **Optimized Alpine base**: Small footprint (~45MB compressed)
- **TLS by default**: Automatic Let's Encrypt integration
- **Multi-architecture**: Supports linux/amd64 and linux/arm64
- **Cloud-native**: Perfect for Kubernetes, Docker Swarm, and standalone Docker
- **Bare-metal ready**: Systemd service file included for non-containerized deployments

---

## ⚡ Quick Start

### Prerequisites

- Docker 24.x+ and Docker Compose v2.x+

### 1. Pull the Image
```bash
docker pull ghcr.io/miguel-devops/caddy-waf:v2.0.0
```

### 2. Create Environment File
```bash
cp .env.example .env
# Edit .env with your domain/backend/image values
```

### 3. Create Runtime Caddyfile From Template
```bash
cp Caddyfile.example Caddyfile
# Edit Caddyfile for your domain and upstreams
```

### 4. Build Your Custom Image (Recommended for your own distribution)
```bash
docker build -t your-registry/your-caddy-waf:custom \
  --build-arg CORAZA_CADDY_REF=v2.2.0 \
  --build-arg CADDY_RATELIMIT_REF=v0.1.0 \
  --build-arg CADDY_DNS_CLOUDFLARE_REF=v0.2.3 \
  .
```

Then set `CADDY_WAF_IMAGE=your-registry/your-caddy-waf:custom` in `.env`.

### 5. Basic Caddyfile Configuration
```caddyfile
{
    order coraza_waf first
}

yourdomain.com {
    respond "Caddy with Coraza WAF is running" 200
}
```

### 6. Start the Container
```bash
docker compose up -d
```

---

## 🏗️ Architecture

```
caddy-waf/
├── assets/                   # Brand assets (logo)
├── deploy/
│   └── systemd/              # Systemd service unit for bare-metal
├── .github/workflows/        # CI/CD (build, scan, sign, push)
├── Dockerfile                # Multi-stage build with pinned plugins
├── docker-compose.yml        # Production-grade compose with security hardening
├── Caddyfile                 # Runtime configuration (WAF + TLS + reverse proxy)
├── Caddyfile.example         # Templated configuration with 5 deployment examples
├── .env.example              # Environment variable template (3 groups)
├── TUNING.md                 # WAF tuning guide per application type
├── ROADMAP.md                # Planned enhancements and compliance roadmap
├── CHANGELOG.md              # Version history (Keep a Changelog)
├── CONTRIBUTING.md           # Contribution guidelines
├── SECURITY.md               # Vulnerability disclosure policy
└── LICENSE                   # MIT License
```

### Data flow

```mermaid
flowchart LR
    Client[Client] -->|HTTPS :443| Caddy[Caddy v2.11]
    Caddy -->|WAF layer| Coraza[Coraza WAF v2.2.0]
    Coraza -->|OWASP CRS v4.23.0| Rules[290+ Rules]
    Coraza -->|Decision| Action{Allow?}
    Action -->|Yes| Backend[Upstream Backend]
    Action -->|No| Block[Block + Audit Log]
    Block -->|JSON| SIEM[SIEM / Log Aggregator]
    Caddy -->|Auto TLS| LE[Let's Encrypt]
```

---

## 📖 Configuration Guide

### WAF Modes
The WAF operates in three modes (configured in Caddyfile):

1. **DetectionOnly** (Default): Logs attacks without blocking — perfect for initial deployment
2. **On**: Active protection — blocks malicious requests
3. **Off**: Disables WAF completely

> **Recommended rollout:** Keep `SecRuleEngine DetectionOnly` for a 7–14 day observation window. Review audit logs, tune CRS exclusions, then switch to `SecRuleEngine On` only after establishing a stable false-positive baseline.

### Example Caddyfile with WAF
```caddyfile
{
    email admin@example.com
    order coraza_waf first

    # JSON logging for observability
    log {
        output stdout
        format json
    }
}

(waf) {
    coraza_waf {
        directives `
            Include /etc/caddy/coraza.conf
            Include /etc/caddy/owasp-crs/crs-setup.conf
            Include /etc/caddy/owasp-crs/rules/*.conf

            # Start with DetectionOnly, change to On after tuning
            SecRuleEngine DetectionOnly

            # Audit logging
            SecAuditEngine RelevantOnly
            SecAuditLog /dev/stdout
            SecAuditLogFormat JSON
        `
    }
}

# Your site configuration
example.com {
    import waf
    reverse_proxy backend:8080
}
```

### Advanced Configuration
For detailed WAF tuning, rule exceptions, and performance optimization, see the complete [TUNING GUIDE](TUNING.md).

Project roadmap and planned security integrations are tracked in [ROADMAP.md](ROADMAP.md).

### Using Custom OWASP CRS Rules
Mount your custom rules directory:
```yaml
volumes:
  - ./custom-crs:/etc/caddy/owasp-crs
```

### Environment Variables
| Variable | Default | Description |
|----------|---------|-------------|
| `CADDY_WAF_IMAGE` | `ghcr.io/miguel-devops/caddy-waf:v2.0.0` | Caddy WAF image reference |
| `EXAMPLE_APP_IMAGE` | `containous/whoami:latest` | Demo backend image |
| `SITE_ADDRESS` | `localhost` | Site address/server name used by Caddy |
| `BACKEND_UPSTREAM` | `example-app:80` | Reverse proxy backend upstream |
| `ACME_EMAIL` | (empty) | Email for Let's Encrypt certificates |
| `CADDY_ADAPTER` | `caddyfile` | Configuration adapter to use |

### Plugins Included
- `github.com/corazawaf/coraza-caddy/v2@v2.2.0` — Coraza WAF integration
- `github.com/mholt/caddy-ratelimit@v0.1.0` — Rate limiting (DDoS protection)
- `github.com/caddy-dns/cloudflare@v0.2.3` — Cloudflare DNS for ACME challenges

---

## 🐳 Docker Deployment

### Default compose stack
```bash
# Start with example backend
cp .env.example .env
cp Caddyfile.example Caddyfile
docker compose up -d
```

### Build from source
```bash
docker build \
  --build-arg CORAZA_CADDY_REF=v2.2.0 \
  --build-arg CADDY_RATELIMIT_REF=v0.1.0 \
  --build-arg CADDY_DNS_CLOUDFLARE_REF=v0.2.3 \
  -t caddy-waf:custom .
```

### Systemd deployment (bare-metal)
```bash
sudo cp deploy/systemd/caddy-waf.service /etc/systemd/system/
sudo useradd -r -s /usr/sbin/nologin caddy-waf
sudo systemctl daemon-reload
sudo systemctl enable --now caddy-waf
```

### Supply chain verification

Verify the image signature before pulling in production:

```bash
cosign verify \
  --certificate-identity "https://github.com/Miguel-DevOps/caddy-waf/.github/workflows/docker-build-scan-sign.yml@refs/heads/main" \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  ghcr.io/miguel-devops/caddy-waf@sha256:<digest>
```

> **Tip:** Use immutable image digests (`@sha256:...`) instead of version tags in production for deterministic deployments.

---

## 🧪 Testing & Validation

### Verify Installation
```bash
# Check container health
docker ps --filter "name=caddy-waf"

# View logs
docker logs caddy-waf

# Test WAF is working
curl -I https://yourdomain.com
```

### Security Scanning
```bash
# Scan image with Trivy
docker run --rm aquasec/trivy image ghcr.io/miguel-devops/caddy-waf:v2.0.0

# Scan with Docker Scout
docker scout quickview ghcr.io/miguel-devops/caddy-waf:v2.0.0
```

---

## 📈 Monitoring & Observability

### Log Structure
```json
{
  "level": "info",
  "ts": 1678901234.567,
  "logger": "http.log.access",
  "msg": "handled request",
  "request": {
    "method": "GET",
    "uri": "/test",
    "proto": "HTTP/2",
    "remote_ip": "192.168.1.100"
  },
  "waf_action": "detected",
  "waf_rule_id": "941100"
}
```

### WAF Metrics to Monitor
- `coraza_waf_processed_total` — Total requests processed
- `coraza_waf_blocked_total` — Requests blocked by WAF
- `coraza_waf_rules_triggered` — Rules triggered (by ID)

---

## 🔒 Security

This project follows a coordinated disclosure policy.
If you discover a vulnerability, **do not open a public issue**.
See [SECURITY.md](./SECURITY.md) for:
- Supported versions
- Reporting instructions (GitHub Advisory + email)
- Response timelines (48h acknowledgment, 30-day fix target)
- Supply chain verification (Cosign + Trivy)

### Supported versions

| Version | Supported |
|---------|-----------|
| 2.0.x   | ✅ Yes    |
| 1.0.x   | ❌ No     |

---

## 📋 Changelog

See [CHANGELOG.md](./CHANGELOG.md) for the full version history.
The project follows [Keep a Changelog](https://keepachangelog.com/) and [Semantic Versioning](https://semver.org/).

| Version | Date | Highlights |
|---------|------|------------|
| [Unreleased] | — | Cosign signing, Trivy scanning, audit improvements |
| [2.0.0](./CHANGELOG.md#200--2026-03-14) | 2026-03-14 | Security hardening, systemd, OCI labels, CI updates |
| [1.0.0](./CHANGELOG.md#100--2026-02-09) | 2026-02-09 | Initial release with Coraza WAF + OWASP CRS |

---

## 🤝 Contributing

Contributions are welcome. Please read [CONTRIBUTING.md](./CONTRIBUTING.md) before opening a pull request.
This project follows [Conventional Commits](https://www.conventionalcommits.org/) and the Developmi engineering standard.

### Quick links
- **Report a bug or request a feature:** [GitHub Issues](https://github.com/Miguel-DevOps/caddy-waf/issues)
- **Advanced configuration:** [TUNING.md](TUNING.md)
- **Roadmap:** [ROADMAP.md](ROADMAP.md)

### Commercial Support
For enterprise support, custom configurations, or security consulting:
- **Website:** [developmi.com](https://developmi.com)
- **Email:** miguel@developmi.com
- **GitHub:** [Miguel-DevOps](https://github.com/Miguel-DevOps)

---

## 📄 License

Copyright © 2026 Miguel Lozano | Developmi. All rights reserved.
Licensed under the [MIT License](./LICENSE).

## 🙏 Acknowledgments

- [Caddy Server](https://caddyserver.com) — Amazing web server with automatic HTTPS
- [Coraza WAF](https://coraza.io) — Enterprise-grade WAF engine
- [OWASP Core Rule Set](https://coreruleset.org) — Industry-standard protection rules
- [Developmi](https://developmi.com) — DevOps & Security consulting

---

## 🤝 Contact & Support

**Maintained by:** Miguel Lozano | Developmi

- **Role:** Cloud & Infrastructure Engineer | FinOps & Bare Metal Specialist | AI Sovereignty Strategist under NIST/DORA Standards
- **Philosophy:** _Security is not a feature; it is the baseline._
- **Website:** [developmi.com](https://developmi.com)
- **GitHub:** [Miguel-DevOps](https://github.com/Miguel-DevOps)
- **LinkedIn:** [Miguel Lozano](https://www.linkedin.com/in/miguel-dev-ops)

---

© 2026 Miguel Lozano | Developmi. All rights reserved.
