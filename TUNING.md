# OWASP CRS Tuning Guide for Caddy with Coraza WAF

## Recommended Production Configuration

### 1. Initial Operation Mode

To avoid false positives during initial deployment, configure WAF in detection mode:

```caddyfile
directives `
    Include /etc/caddy/coraza.conf
    Include /etc/caddy/owasp-crs/crs-setup.conf
    Include /etc/caddy/owasp-crs/rules/*.conf
    
    # Detection mode only (does not block)
    SecRuleEngine DetectionOnly
    
    # Audit logging
    SecAuditEngine RelevantOnly
    SecAuditLog /dev/stdout
    SecAuditLogFormat JSON
`
```

After a prudent monitoring period (commonly 7-14 days, based on traffic diversity and release frequency), change to:
```caddyfile
SecRuleEngine On
```

### 2. Common Exceptions by Application Type

#### REST/JSON APIs
```caddyfile
directives `
    # Disable problematic rules for JSON
    SecRuleRemoveById 932100
    SecRuleRemoveById 933100
    SecRuleRemoveById 942100
    
    # Increase limits for large payloads
    SecRequestBodyLimit 134217728
    SecPcreMatchLimit 100000
    SecPcreMatchLimitRecursion 100000
`
```

#### GraphQL
```caddyfile
directives `
    # GraphQL uses long queries with special characters
    SecRuleRemoveById 932100
    SecRuleRemoveById 933100
    SecRuleRemoveById 942100
    SecRuleRemoveById 942200
    
    # Allow GraphQL special characters
    SecRuleUpdateTargetById 932100 !REQUEST_BODY
    SecRuleUpdateTargetById 933100 !REQUEST_BODY
`
```

#### Traditional Web Applications
```caddyfile
directives `
    # Standard configuration
    SecRuleEngine On
    
    # Exclude specific parameters from your application
    SecRuleRemoveTargetById 942100 "ARGS:search_term"
    SecRuleRemoveTargetById 941100 "ARGS:comment"
`
```

### 3. Critical Rules to Monitor

| Rule ID | Description | Recommended Action |
|---------|-------------|-------------------|
| 920270 | Invalid character in request | Verify frontend encoding |
| 942100 | SQL Injection Attack Detected | Verify if false positive |
| 932100 | Remote Command Execution | Review file uploads |
| 933100 | PHP Injection Attack | Only relevant if using PHP |
| 941100 | XSS Attack Detected | Validate frontend sanitization |

### 4. Performance and Limits

```caddyfile
directives `
    # Optimize performance
    SecRequestBodyLimit 134217728  # 128MB
    SecRequestBodyNoFilesLimit 131072  # 128KB
    SecPcreMatchLimit 100000
    SecPcreMatchLimitRecursion 100000
    SecCollectionTimeout 600
    
    # Limit processed rules
    SecRuleEngine On
    SecAction "id:900000,phase:1,nolog,pass,t:none,setvar:tx.anomaly_score_threshold=5"
    SecAction "id:900001,phase:1,nolog,pass,t:none,setvar:tx.paranoia_level=1"
`
```

### 5. Monitoring and Alerts

#### Key metrics to monitor:
- `coraza_waf_blocked_total` - Blocked requests
- `coraza_waf_processed_total` - Processed requests
- `coraza_waf_rules_triggered` - Rules triggered by ID

#### Log configuration for SIEM:
```caddyfile
log {
    output stdout
    format json {
        time_format "iso8601"
        level "info"
    }
}

directives `
    # Detailed Coraza logs
    SecAuditEngine RelevantOnly
    SecAuditLog /dev/stdout
    SecAuditLogFormat JSON
    SecAuditLogParts ABCDEFGHIJKZ
`
```

### 6. CRS Rules Update

To update OWASP CRS without rebuilding the image:

1. **Method A**: Mount volume with updated rules
```yaml
volumes:
  - ./owasp-crs:/etc/caddy/owasp-crs
```

2. **Method B**: Update script in init container
```bash
#!/bin/sh
set -euo pipefail

CRS_VERSION="v4.23.0"
# Verify the checksum in the official release artifacts before use.
CRS_SHA256="PENDING_MANUAL_VERIFICATION"

wget -q -O /tmp/coreruleset.tar.gz "https://github.com/coreruleset/coreruleset/archive/refs/tags/${CRS_VERSION}.tar.gz"
echo "${CRS_SHA256}  /tmp/coreruleset.tar.gz" | sha256sum -c -
tar xzf /tmp/coreruleset.tar.gz -C /etc/caddy/owasp-crs --strip-components=1
rm -f /tmp/coreruleset.tar.gz
```

### 7. Troubleshooting

#### Common false positives:
1. **Legitimate User-Agents**: Add exceptions in `crs-setup.conf`
2. **Parameters with complex content**: Use `SecRuleRemoveTargetById`
3. **APIs with special formats**: Configure `SecRuleUpdateTargetById`

#### Temporary debug mode:
```caddyfile
directives `
    SecDebugLog /dev/stdout
    SecDebugLogLevel 3
`
```

### 8. Resources

- [OWASP CRS Documentation](https://coreruleset.org/docs/)
- [Coraza WAF Configuration](https://coraza.io/docs/)
- [Caddy with Coraza](https://github.com/corazawaf/coraza-caddy)
- [CRS Rules GitHub](https://github.com/coreruleset/coreruleset)