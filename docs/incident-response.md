# Incident response: WAF false positives

Runbook for handling WAF incidents in caddy-waf, focused on the most common
case — OWASP CRS blocking legitimate traffic (false positives) — plus the
generic incident workflow. Keep it open next to the running deployment:
every command is copy-paste.

## When to suspect a false positive

- Users report being blocked (403) on requests that look legitimate
- The same request works from another client or with WAF `DetectionOnly`
- The blocked request triggers a CRS rule that is known to be noisy for your
  application type (see TUNING.md for per-app guidance)
- Blocked traffic appears in bursts for one rule ID, not spread across many

Mode matters:

| Mode | What happens | Implication |
|------|--------------|-------------|
| `DetectionOnly` (default, Caddyfile:30) | Coraza logs the match, **never blocks** | Blocked users cannot come from the WAF — look at your backend, network, or rate limiter |
| `On` | Coraza blocks with 403 (Coraza's default) | A 403 with `waf_rule_id` in the audit log is a real WAF block |

Note: CRS 4.28.0 is intentionally sensitive (290+ rules covering SQLi, XSS,
command injection, path traversal). Payloads that *look* like an attack — e.g.
a search for `1; DROP TABLE`, an email containing `<script>`, or URLs with
encoded path segments — are routinely flagged. In `DetectionOnly` these show
up only as log entries; after switching to `On` they become user-facing 403s.

## Triage

1. **Confirm the block is the WAF.** Inspect the audit log for the request:

   ```bash
   # Docker Compose
   docker compose logs caddy-waf | grep '"waf_action":"blocked"' | tail -20

   # systemd
   journalctl -u caddy-waf | grep 'waf_action.*blocked' | tail -20
   ```

2. **Identify the rule.** Each audit log line carries the rule ID:

   ```json
   { "waf_rule_id": "941100", "waf_action": "blocked", "uri": "/search?q=..." }
   ```

3. **Reproduce and confirm the rule fires.** Run the exact request through the
   WAF and compare. The go-ftw integration suite covers the baseline:

   ```bash
   make test-waf        # starts the test container on 127.0.0.1:9090, runs 4 cases, tears down
   ```

   For the suspect rule, check the rule definition and its exclusion advice:

   ```bash
   grep -rn "941100" /etc/caddy/owasp-crs/rules/   # compose: docker compose exec caddy-waf grep -rn ...
   ```

4. **Decide.** If the request is genuinely malicious → no action (this is the
   WAF doing its job; harden the app if it is being targeted). If it is
   legitimate traffic → remediate (below).

## Remediation

Pick the smallest change first; re-verify after every change.

### Option A — exclude the specific rule (preferred)

Add `SecRuleRemoveById` inside the `coraza_waf` block of the runtime Caddyfile
(compose: `./Caddyfile`; systemd: `/etc/caddy/Caddyfile`):

```caddyfile
coraza_waf {
    directives `
        Include /etc/caddy/coraza.conf
        Include /etc/caddy/owasp-crs/crs-setup.conf
        Include /etc/caddy/owasp-crs/rules/*.conf

        SecRuleEngine On
        SecRuleRemoveById 941100
    `
}
```

Apply and verify:

```bash
docker compose up -d --force-recreate        # Docker Compose
sudo systemctl reload caddy-waf              # systemd (config-only, no downtime)
```

Follow up with a per-rule tuning entry in TUNING.md so the exclusion is
documented, not folklore.

### Option B — switch the site to DetectionOnly while investigating

When legitimate traffic is being impacted and the exclusion is not yet
identified, restore availability first:

```caddyfile
SecRuleEngine DetectionOnly
```

Apply with the same reload commands as Option A. Users are served again and
the WAF keeps logging, which lets you identify the offending rule calmly.

### Option C — re-deploy a clean state

If the Caddyfile or rule files got corrupted during changes:

```bash
docker compose up -d --force-recreate --no-deps caddy-waf   # Compose
sudo systemctl restart caddy-waf                             # systemd
```

## Verify the fix

- [ ] `make test-waf` passes (4/4 go-ftw cases)
- [ ] The previously blocked request now succeeds (200) with `SecRuleEngine On`
- [ ] The excluded rule no longer appears in the audit log for that request
- [ ] Other rules still block real attack payloads (spot-check with
      `curl -i 'http://127.0.0.1:9090/?q=<script>alert(1)</script>'` against
      the test instance)

## Communication and post-incident

| Step | Action |
|------|--------|
| During | Notify the affected application owner; state what is being done and the ETA for the decision (exclude rule vs. DetectionOnly) |
| After | Document the exclusion in TUNING.md; note the rule ID, affected path/param, and date |
| Review | Re-check the exclusion at the next CRS update (rules can change between CRS versions); plan removal if upstream fixes the false positive |
| Metrics | Record incident duration and rule IDs involved — this feeds the observation window decision to move to `SecRuleEngine On` |

## Severity and response times

| Severity | Example | Response target | First action |
|----------|---------|-----------------|--------------|
| S1 — Critical | Full site blocked (all users 403) | Immediate | Switch to `DetectionOnly` (Option B), then investigate |
| S2 — High | One route or app blocked | 1 business hour | Triage; exclude the rule if confirmed FP |
| S3 — Medium | Some users/patterns blocked intermittently | 4 business hours | Triage; tune per TUNING.md |
| S4 — Low | DetectionOnly logs show noisy rules | Next tuning window | Add exclusion + test before `On` switch |

Security vulnerabilities follow SECURITY.md (coordinated disclosure, 48h
acknowledgment) — do not handle them through this runbook.
