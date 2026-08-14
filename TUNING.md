# OWASP CRS Tuning Guide for Caddy with Coraza WAF

A practical guide to configuring, tuning, and operating the OWASP Core Rule Set (CRS) v4.28.0 with Coraza WAF on Caddy.

---

## 1. Understanding Paranoia Levels

CRS 4.x organizes rules into **four paranoia levels (PL1–PL4)**. Each level adds more rules - more security, but also more potential false positives.

| Level | Profile | False Positives | Use Case |
|-------|---------|----------------|----------|
| **PL1** (default) | Core rules, safe for most sites | Minimal | Public-facing sites, APIs, blogs |
| **PL2** | Real user data protection | Moderate | E-commerce, SaaS platforms |
| **PL3** | Banking-grade security | High | Financial, health, sensitive data |
| **PL4** | Maximum paranoia | Very high | Defense-in-depth, compliance mandates |

### Blocking vs. Executing Paranoia Level

CRS 4.x introduces **two separate settings**:
- `tx.blocking_paranoia_level` - rules that **count toward the anomaly score** and can block
- `tx.executing_paranoia_level` - rules that **run but don't add to the anomaly score** (observe only)

This lets you **test a higher paranoia level before enforcing it**:

```caddyfile
directives `
    # Execute PL2 rules but only block at PL1 level
    SecAction "id:900000,phase:1,pass,nolog,t:none,\
      setvar:tx.blocking_paranoia_level=1,\
      setvar:tx.executing_paranoia_level=2"
`
```

> In CRS 4.x, `tx.executing_paranoia_level` is also known as `tx.detection_paranoia_level`. Both names work. The coraza.conf-recommended ships with both defaulting to 1.

---

## 2. Recommended Adoption Flow

### Phase 1 - Observation (Days 1–14)

Run in **DetectionOnly** mode at PL1. No traffic is blocked.

```caddyfile
SecRuleEngine DetectionOnly

# CRS at default paranoia (PL1)
SecAction "id:900000,phase:1,pass,nolog,t:none,\
  setvar:tx.blocking_paranoia_level=1"
```

### Phase 2 - Graduated Paranoia (Days 15–28)

Set `executing_paranoia_level=2` while keeping `blocking_paranoia_level=1`. PL2 rules run but don't block - you collect data on what would be blocked.

```caddyfile
SecRuleEngine DetectionOnly

SecAction "id:900000,phase:1,pass,nolog,t:none,\
  setvar:tx.blocking_paranoia_level=1,\
  setvar:tx.executing_paranoia_level=2"
```

**Check logs weekly.** Create rule exclusions for any false positives you find. See [section 4](#4-common-exceptions-by-application-type).

### Phase 3 - Enforcement with PL2 (Days 29+)

Once PL2 false positives are tuned:

```caddyfile
SecRuleEngine On

SecAction "id:900000,phase:1,pass,nolog,t:none,\
  setvar:tx.blocking_paranoia_level=2,\
  setvar:tx.executing_paranoia_level=2"

# Anomaly threshold - 5 is the CRS recommended default
setvar:tx.inbound_anomaly_score_threshold=5
```

Repeat the same pattern (observe → tune → enable) for PL3 and PL4 if your risk profile requires it.

---

## 3. Anomaly Scoring Configuration

CRS uses an **anomaly scoring** model. Each matched rule adds a score; if the inbound score exceeds the threshold, the request is blocked.

### Default Thresholds

```caddyfile
# Standard values from coraza.conf-recommended
SecAction "id:900000,phase:1,pass,nolog,t:none,\
  setvar:tx.inbound_anomaly_score_threshold=5,\
  setvar:tx.outbound_anomaly_score_threshold=4"
```

### Tuning the Threshold

| Threshold | Effect |
|-----------|--------|
| **5** (default) | Blocks after ~1 CRITICAL or ~2 HIGH matches. Recommended by CRS project. |
| **10** | Allows more anomalous traffic through. Use only if you have extreme false positive rates. |
| **3** | More aggressive blocking. May catch evasion attempts that barely trigger rules. |

> A threshold of **5** is the CRS-recommended default and works for most deployments. Only change it after data from your observation window.

---

## 4. Common Exceptions by Application Type

### REST/JSON APIs

APIs often trigger false positives on JSON payloads with special characters.

```caddyfile
directives `
    # Paranoia level 1 - safe baseline
    SecAction "id:900000,phase:1,pass,nolog,t:none,\
      setvar:tx.blocking_paranoia_level=1"

    # Disable specific rules that conflict with JSON payloads
    SecRuleRemoveById 932100    # Remote Command Execution
    SecRuleRemoveById 933100    # PHP Injection
    SecRuleRemoveById 942100    # SQL Injection

    # Increase limits for API payloads
    SecRequestBodyLimit 134217728        # 128 MB
    SecRequestBodyNoFilesLimit 131072    # 128 KB
    SecPcreMatchLimit 100000
    SecPcreMatchLimitRecursion 100000
`
```

### GraphQL

GraphQL queries use special characters and long query strings that trigger false positives.

```caddyfile
directives `
    SecAction "id:900000,phase:1,pass,nolog,t:none,\
      setvar:tx.blocking_paranoia_level=1"

    # Common GraphQL false positive rules
    SecRuleRemoveById 932100    # Remote Command Execution
    SecRuleRemoveById 933100    # PHP Injection
    SecRuleRemoveById 942100    # SQL Injection
    SecRuleRemoveById 942200    # SQL Comment Injection

    # Limit paranoia for GraphQL introspection queries
    SecRuleUpdateTargetById 932100 !REQUEST_BODY
    SecRuleUpdateTargetById 933100 !REQUEST_BODY
`
```

### Traditional Web Applications

For standard web apps with user-generated content:

```caddyfile
directives `
    SecAction "id:900000,phase:1,pass,nolog,t:none,\
      setvar:tx.blocking_paranoia_level=1"

    # Parameter-specific exclusions (adjust for your app)
    SecRuleRemoveTargetById 942100 "ARGS:search_term"
    SecRuleRemoveTargetById 941100 "ARGS:comment"
    SecRuleRemoveTargetById 941100 "ARGS:message"

    # Increase PCRE limits for complex pages
    SecPcreMatchLimit 250000
    SecPcreMatchLimitRecursion 250000
`
```

> **Tip:** Use the rule exclusion packages shipped with CRS for popular platforms (WordPress, Drupal, Nextcloud, etc.). Mount `owasp-crs/plugins/` and enable them in `crs-setup.conf`.

### File Upload Endpoints

File uploads frequently trigger CRS rules. Narrow exclusions to specific parameters:

```caddyfile
directives `
    # Only exclude ARGS:file_content, not the whole rule
    SecRuleRemoveTargetById 933210 "ARGS:file_content"
    SecRuleRemoveTargetById 934100 "ARGS:file_content"
`
```

---

## 5. Performance and Limits

### Recommended Production Limits

```caddyfile
directives `
    # Body limits
    SecRequestBodyLimit 134217728          # 128 MB
    SecRequestBodyNoFilesLimit 131072      # 128 KB

    # PCRE performance
    SecPcreMatchLimit 100000
    SecPcreMatchLimitRecursion 100000

    # Collection timeout
    SecCollectionTimeout 600

    # Anomaly threshold (CRS-recommended default)
    SecAction "id:900000,phase:1,pass,nolog,t:none,\
      setvar:tx.inbound_anomaly_score_threshold=5,\
      setvar:tx.outbound_anomaly_score_threshold=4,\
      setvar:tx.blocking_paranoia_level=1,\
      setvar:tx.executing_paranoia_level=1"
`
```

### Notes

- **PL1** adds negligible overhead. Going from PL1 → PL2 roughly doubles rule processing.
- **PL3–PL4** can add 3–5× more rules. Only enable if your security requirements justify it.
- The `coraza.conf-recommended` shipped with v3.7.0 already includes optimized defaults. Mounting a custom `coraza.conf` is unnecessary unless you need non-standard tuning.

---

## 6. Monitoring and Alerts

### Caddy Metrics (admin /metrics)

The Caddy admin endpoint (`:2019/metrics`) exposes Prometheus metrics. With the
observability stack enabled, scrape this endpoint with either backend:

- `caddy_http_requests_total` - Total requests (labels: server, handler, method)
- `caddy_http_request_duration_seconds` - Request latency histogram (labels include `code`)
- `caddy_http_requests_in_flight` - Concurrent requests gauge
- `caddy_reverse_proxy_upstreams_healthy` - Backend upstream health (0/1)
- `caddy_config_last_reload_successful` - Config reload status

> **Note:** coraza-caddy v2.5.0 does not export `coraza_waf_*` metrics (upstream
> limitation). WAF rule IDs and decisions are in the JSON audit log on stdout.

See [README.md: Observability](README.md#-observability-metrics--dashboards)
for the dual-backend (VictoriaMetrics + Prometheus) setup with Grafana.

### Log Configuration for SIEM

```caddyfile
log {
    output stdout
    format json {
        time_format "iso8601"
        level "info"
    }
}

coraza_waf {
    directives `
        SecAuditEngine RelevantOnly
        SecAuditLog /dev/stdout
        SecAuditLogFormat JSON
        SecAuditLogParts ABCDEFGHIJKZ
    `
}
```

### Key Metrics to Watch

| Rule ID | Description | Action on Spike |
|---------|-------------|----------------|
| 920270 | Invalid character in request | Check frontend encoding |
| 942100 | SQL Injection detected | Investigate - rarely false positive |
| 932100 | Remote Command Execution | Review file upload flows |
| 941100 | XSS Attack detected | Validate sanitization |
| 942200 | SQL Comment Injection | Check API query parameters |

---

## 7. Updating CRS Rules Without Rebuilding

### Method A - Volume Mount

Mount updated CRS rules as a volume. The container uses the mounted rules instead of the baked-in ones:

```yaml
volumes:
  - ./owasp-crs:/etc/caddy/owasp-crs:ro
```

### Method B - Init Script

Add an init container or sidecar that downloads and verifies the rules:

```bash
#!/bin/sh
set -euo pipefail

CRS_VERSION="v4.28.0"
CRS_SHA256="d8acc96f25ad07c8e3a595a23c797324f6d77e59ddf9e26e90dd95ebd2e676ce"

wget -q -O /tmp/coreruleset.tar.gz \
  "https://github.com/coreruleset/coreruleset/archive/refs/tags/${CRS_VERSION}.tar.gz"

echo "${CRS_SHA256}  /tmp/coreruleset.tar.gz" | sha256sum -c -

tar xzf /tmp/coreruleset.tar.gz -C /etc/caddy/owasp-crs --strip-components=1
rm -f /tmp/coreruleset.tar.gz
```

> **Always verify the SHA256 checksum** from the [official CRS releases](https://github.com/coreruleset/coreruleset/releases) before applying.

---

## 8. Troubleshooting

### Common False Positive Patterns

1. **Legitimate User-Agents getting blocked** - Add exceptions in `crs-setup.conf`
2. **Parameters with Base64/JSON content** - Use `SecRuleRemoveTargetById` scoped to the specific parameter
3. **APIs with GraphQL introspection** - Create targeted exclusions for the introspection endpoint
4. **File uploads with binary content** - Remove `933210` and `934100` only for upload routes

### Temporary Debug Mode

```caddyfile
coraza_waf {
    directives `
        SecDebugLog /dev/stdout
        SecDebugLogLevel 3

        # CRS test mode - run all rules including PL4
        SecAction "id:900000,phase:1,pass,nolog,t:none,\
          setvar:tx.blocking_paranoia_level=4,\
          setvar:tx.executing_paranoia_level=4"
    `
}
```

> ⚠️ Never run with `SecDebugLogLevel 3` or `paranoia_level=4` in production. Use only for targeted debugging on staging.

### Quick Reference - CRS Rule Categories

| Prefix | Category | Common False Positives |
|--------|----------|----------------------|
| 93xxx | RCE, PHP Injection | File uploads, CLI tools |
| 94xxx | SQL Injection | Search params, JSON payloads |
| 95xxx | Data Leakage | Debug endpoints |
| 96xxx | Scanner Detection | Monitoring tools |
| 92xxx | Protocol/Encoding | External health checks |

---

## 9. References

- [OWASP CRS Documentation](https://coreruleset.org/docs/)
- [CRS Paranoia Levels](https://coreruleset.org/docs/2-how-crs-works/2-2-paranoia_levels)
- [Coraza WAF Configuration](https://coraza.io/docs/)
- [Coraza with Caddy](https://github.com/corazawaf/coraza-caddy)
- [CRS Releases & Checksums](https://github.com/coreruleset/coreruleset/releases)
- [Coraza conf-recommended (v3.7.0)](https://github.com/corazawaf/coraza/blob/v3.7.0/coraza.conf-recommended)
