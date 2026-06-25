# Build Stage
FROM caddy:2.11-builder AS builder

# Build args for deterministic plugin references.
# Verify stable refs upstream before release:
# - https://github.com/mholt/caddy-ratelimit
# - https://github.com/caddy-dns/cloudflare
ARG CORAZA_CADDY_REF=v2.2.0
ARG CADDY_RATELIMIT_REF=v0.1.0
ARG CADDY_DNS_CLOUDFLARE_REF=v0.2.3

# Build Caddy with fully pinned plugin refs.
RUN xcaddy build \
    --with github.com/corazawaf/coraza-caddy/v2@${CORAZA_CADDY_REF} \
    --with github.com/mholt/caddy-ratelimit@${CADDY_RATELIMIT_REF} \
    --with github.com/caddy-dns/cloudflare@${CADDY_DNS_CLOUDFLARE_REF}

# Final Stage
FROM caddy:2.11

# Container metadata
LABEL org.opencontainers.image.authors="Miguel Lozano <miguel@developmi.com>"
LABEL org.opencontainers.image.source="https://github.com/Miguel-DevOps/caddy-waf"
LABEL org.opencontainers.image.description="Production-ready Caddy web server with Coraza WAF and OWASP CRS"
LABEL org.opencontainers.image.licenses="MIT"
LABEL maintainer="Miguel Lozano"
LABEL vendor="Developmi"
LABEL version="2.11.0"
LABEL waf.coraza.version="2.2.0"
LABEL waf.owasp-crs.version="4.23.0"

# Copy the custom binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# --- WAF SETUP ---

# Validate this checksum from Coraza upstream before each release.
ARG CORAZA_CONF_SHA256=84389d00eabf41f352812949d88d841e1e4f09b719794d85fd86eccace3e3a55

# Install dependencies, download CRS and configure WAF in a single layer
RUN mkdir -p /etc/caddy/owasp-crs /tmp/downloads && \
    # Ensure wget and tar are available (Alpine base includes them)
    apk add --no-cache wget tar && \
    # Download OWASP CRS v4.23.0 source archive with SHA256 verification
    wget -q -O /tmp/downloads/coreruleset.tar.gz https://github.com/coreruleset/coreruleset/archive/refs/tags/v4.23.0.tar.gz && \
    # Verify SHA256 checksum (pre-calculated for v4.23.0 source archive)
    echo "56ef52ffdb055a5bbf6e487e1f4256e5267c44d9c0c4a3cb982fad44380125e3  /tmp/downloads/coreruleset.tar.gz" | sha256sum -c - && \
    tar xzf /tmp/downloads/coreruleset.tar.gz -C /etc/caddy/owasp-crs --strip-components=1 && \
    rm -f /tmp/downloads/coreruleset.tar.gz && \
    # Prepare CRS Setup file
    cp /etc/caddy/owasp-crs/crs-setup.conf.example /etc/caddy/owasp-crs/crs-setup.conf && \
    # Download base Coraza configuration v3.3.3
    wget -q -O /tmp/downloads/coraza.conf https://raw.githubusercontent.com/corazawaf/coraza/v3.3.3/coraza.conf-recommended && \
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
RUN chown -R 1337:1337 /etc/caddy/owasp-crs /etc/caddy/coraza.conf && \
    chmod -R 755 /etc/caddy/owasp-crs && \
    chmod 644 /etc/caddy/coraza.conf

# Create default Caddyfile for validation
RUN echo '# Default Caddyfile - replace with volume mount' > /etc/caddy/Caddyfile.default && \
    echo '{' >> /etc/caddy/Caddyfile.default && \
    echo '    # Global configuration' >> /etc/caddy/Caddyfile.default && \
    echo '    log {' >> /etc/caddy/Caddyfile.default && \
    echo '        output stdout' >> /etc/caddy/Caddyfile.default && \
    echo '        format json' >> /etc/caddy/Caddyfile.default && \
    echo '    }' >> /etc/caddy/Caddyfile.default && \
    echo '}' >> /etc/caddy/Caddyfile.default && \
    echo '' >> /etc/caddy/Caddyfile.default && \
    echo ':80 {' >> /etc/caddy/Caddyfile.default && \
    echo '    respond "Caddy WAF is running"' >> /etc/caddy/Caddyfile.default && \
    echo '}' >> /etc/caddy/Caddyfile.default

# Validate Caddy and WAF configuration
RUN caddy validate --config /etc/caddy/Caddyfile.default --adapter caddyfile

## Ensure caddy user exists with UID 1337 and GID 1337 (align with hardening suite)
RUN id -u caddy 2>/dev/null || (addgroup -g 1337 -S caddy && adduser -u 1337 -S caddy -G caddy)

# Switch to non-privileged user (UID 1337)
USER 1337:1337

# Expose ports
EXPOSE 80 443 443/udp

# Define volumes for persistent data
VOLUME ["/data", "/config"]

# Health check - verify Caddy process is active
HEALTHCHECK --interval=30s --timeout=3s --start-period=10s --retries=3 \
    CMD pgrep caddy || exit 1