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
LABEL version="3.1.0"
LABEL waf.coraza.version="2.5.0"
LABEL waf.owasp-crs.version="4.28.0"

# Copy the custom binary
COPY --from=builder /usr/bin/caddy /usr/bin/caddy

# Upgrade base image packages — fix CVEs in c-ares, curl, libcurl
RUN apk upgrade --no-cache c-ares curl libcurl

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