# Build Stage
FROM caddy:2.11.4-builder AS builder

# Build args for deterministic plugin references.
# coraza-caddy: https://github.com/corazawaf/coraza-caddy/releases/tag/v2.5.0
# caddy-ratelimit: https://github.com/mholt/caddy-ratelimit (no release tags beyond v0.1.0 - pinned by commit SHA)
# caddy-dns/cloudflare: https://github.com/caddy-dns/cloudflare/releases/tag/v0.2.4
ARG CORAZA_CADDY_REF=v2.5.0
ARG CADDY_RATELIMIT_REF=5625512
ARG CADDY_DNS_CLOUDFLARE_REF=v0.2.4

# Build Caddy with fully pinned plugin refs.
RUN xcaddy build \
    --with github.com/corazawaf/coraza-caddy/v2@${CORAZA_CADDY_REF} \
    --with github.com/mholt/caddy-ratelimit@${CADDY_RATELIMIT_REF} \
    --with github.com/caddy-dns/cloudflare@${CADDY_DNS_CLOUDFLARE_REF}

# Final Stage
FROM caddy:2.11.4
SHELL ["/bin/ash", "-eo", "pipefail", "-c"]

# Container metadata
LABEL org.opencontainers.image.authors="Miguel Lozano <miguel@developmi.com>"
LABEL org.opencontainers.image.source="https://github.com/Developmi/caddy-waf"
LABEL org.opencontainers.image.description="Production-ready Caddy web server with Coraza WAF and OWASP CRS"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="Miguel Lozano"
LABEL vendor="Developmi"
LABEL version="3.3.1"
LABEL waf.coraza.version="2.5.0"
LABEL waf.owasp-crs.version="4.28.0"

# Copy the custom binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Upgrade all base image packages — pulls current Alpine 3.23 security fixes
# (openssl/libssl, musl, busybox, zlib, ca-certificates, curl, c-ares, ...)
RUN apk upgrade --no-cache

# --- WAF SETUP ---

# Validate this checksum from Coraza upstream before each release.
ARG CORAZA_CONF_SHA256=fea02902c81b2b9691746e08b934dea5ded6382aa7b561c31b9edef00cc5c956

# Install dependencies, download CRS and configure WAF in a single layer
RUN mkdir -p /etc/caddy/owasp-crs /tmp/downloads && \
    # Ensure wget and tar are available (Alpine base includes them)
    apk add --no-cache wget=1.25.0-r2 tar=1.35-r4 && \
    # Download OWASP CRS v4.28.0 source archive with SHA256 verification
    wget -q -O /tmp/downloads/coreruleset.tar.gz https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.28.0.tar.gz && \
    # Verify SHA256 checksum
    echo "d8acc96f25ad07c8e3a595a23c797324f6d77e59ddf9e26e90dd95ebd2e676ce  /tmp/downloads/coreruleset.tar.gz" | sha256sum -c - && \
    tar xzf /tmp/downloads/coreruleset.tar.gz -C /etc/caddy/owasp-crs --strip-components=1 && \
    rm -f /tmp/downloads/coreruleset.tar.gz && \
    # Prepare CRS Setup file
    cp /etc/caddy/owasp-crs/crs-setup.conf.example /etc/caddy/owasp-crs/crs-setup.conf && \
    # Download base Coraza configuration v3.7.0
    wget -q -O /tmp/downloads/coraza.conf https://raw.githubusercontent.com/corazawaf/coraza/v3.7.0/coraza.conf-recommended && \
    echo "$CORAZA_CONF_SHA256  /tmp/downloads/coraza.conf" | sha256sum -c - && \
    mv /tmp/downloads/coraza.conf /etc/caddy/coraza.conf && \
    rm -rf /tmp/downloads && \
    # Clean apk cache and remove temporary packages
    apk del wget tar && \
    rm -rf /var/cache/apk/* && \
    # Verify critical files exist
    test -f /usr/bin/caddy && \
    test -f /etc/caddy/coraza.conf && \
    test -f /etc/caddy/owasp-crs/crs-setup.conf

## Adjust permissions for non-privileged caddy user (UID 1337, GID 1337)
RUN mkdir -p /data/logs && \
    chown -R 1337:1337 /etc/caddy/owasp-crs /etc/caddy/coraza.conf /data/logs && \
    chmod -R 755 /etc/caddy/owasp-crs && \
    chmod 644 /etc/caddy/coraza.conf

# Default Caddyfile — ACTIVE WAF baseline (DetectionOnly).
# The image CMD runs `caddy run --config /etc/caddy/Caddyfile`, so the loaded
# default is this file; Caddyfile.default is the reference copy. Replace both
# with a volume mount (/etc/caddy/Caddyfile) for real deployments.
RUN cat > /etc/caddy/Caddyfile.default <<'EOF'
# Default Caddyfile - replace with volume mount
{
    # Zero-trust default: admin API bound to loopback only (Caddy default).
    # Bind to 0.0.0.0:2019 ONLY inside an isolated Docker network when the
    # caddy-waf-ui or observability scraping requires it - never host-published.
    admin localhost:2019

    order coraza_waf first

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

            # Default mode for new deployments: monitor first, then enforce.
            SecRuleEngine DetectionOnly
            SecAuditEngine RelevantOnly
            SecAuditLog /data/logs/coraza-audit.log
            SecAuditLogFormat JSON
            SecAuditLogParts ABCDEFGHIJKZ
        `
    }
}

:80 {
    import waf
    respond "Caddy WAF is running"
}
EOF

# Loaded default: the config Caddy actually starts with (CMD default).
RUN cp /etc/caddy/Caddyfile.default /etc/caddy/Caddyfile

# Validate Caddy and WAF configuration
RUN caddy validate --config /etc/caddy/Caddyfile.default --adapter caddyfile

# Coraza provisions /data/logs/coraza-audit.log as root during the validate above;
# re-chown so the baked default config boots as UID 1337 (contract §7/D6).
RUN chown -R 1337:1337 /data/logs

# Build-time release gate: the baked default MUST enable the WAF (contract §9).
# A bare `docker run` of this image must never serve traffic without Coraza.
RUN grep -q 'coraza_waf' /etc/caddy/Caddyfile && \
    grep -q 'SecRuleEngine DetectionOnly' /etc/caddy/Caddyfile && \
    grep -q 'SecAuditLog /data/logs/coraza-audit.log' /etc/caddy/Caddyfile

## Ensure caddy user exists with UID 1337 and GID 1337 (align with hardening suite)
RUN id -u caddy 2>/dev/null || (addgroup -g 1337 -S caddy && adduser -u 1337 -S caddy -G caddy)

# Switch to non-privileged user (UID 1337)
USER 1337:1337

# Expose ports
EXPOSE 80 443 443/udp

# Define volumes for persistent data
VOLUME ["/data", "/config"]

# Health check - verify Caddy admin /metrics endpoint responds (JSON form, DL3025 compliant)
# Uses curl (present in the image) instead of busybox wget (resolves localhost to ::1 and fails)
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD ["curl", "-fs", "http://127.0.0.1:2019/metrics"]