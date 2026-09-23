#!/usr/bin/env bash
# caddy-waf Integration Test Runner
# Starts a test container, runs go-ftw CRS tests, then tears down.
set -Eeuo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/tools/bin"
COMPOSE_FILES="-f $ROOT/docker-compose.yml -f $ROOT/docker-compose.test.yml"

echo "=== Building image (if needed) ==="
docker compose $COMPOSE_FILES build --quiet caddy-waf

echo "=== Starting test container (caddy-waf-test) ==="
docker compose $COMPOSE_FILES up -d --wait caddy-waf

echo "=== Container status ==="
docker ps --filter "name=caddy-waf-test" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

SUITE_PATH="${1:-$ROOT/tests/integration}"
if [[ "$SUITE_PATH" != /* ]]; then
    if [[ -d "$ROOT/$SUITE_PATH" ]]; then
        SUITE_PATH="$ROOT/$SUITE_PATH"
    elif [[ -d "$ROOT/tests/integration/$SUITE_PATH" ]]; then
        SUITE_PATH="$ROOT/tests/integration/$SUITE_PATH"
    fi
fi

echo ""
echo "=== Running WAF integration tests ($SUITE_PATH) ==="
"$BIN/go-ftw" run \
    -d "$SUITE_PATH" \
    --config "$ROOT/tests/ftw.yml" \
    --cloud

echo ""
echo "=== Verifying native security headers and banner suppression ==="
HEADERS="$(curl -s -D - -o /dev/null http://127.0.0.1:9090/)"

# Verify server banners are suppressed
if echo "$HEADERS" | grep -qi '^Server:'; then
    echo "✗ FAIL: Server header is exposed: $(echo "$HEADERS" | grep -i '^Server:')"
    exit 1
fi
if echo "$HEADERS" | grep -qi '^X-Powered-By:'; then
    echo "✗ FAIL: X-Powered-By header is exposed"
    exit 1
fi

# Verify required security headers are present
for header in "Strict-Transport-Security" "X-Content-Type-Options: nosniff" "X-Frame-Options: DENY" "Referrer-Policy: strict-origin-when-cross-origin" "Permissions-Policy" "X-Permitted-Cross-Domain-Policies: none"; do
    if ! echo "$HEADERS" | grep -qi "^${header}"; then
        echo "✗ FAIL: Missing required security header: $header"
        exit 1
    fi
done
echo "✓ Native security headers and banner suppression verified."

echo ""
echo "=== Cleaning up ==="
docker compose $COMPOSE_FILES down --volumes --remove-orphans

echo ""
echo "✓ Integration tests complete."
