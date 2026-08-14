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

echo ""
echo "=== Running WAF integration tests (cloud mode) ==="
"$BIN/go-ftw" run \
    -d "$ROOT/tests/integration" \
    --config "$ROOT/tests/ftw.yml" \
    --cloud

echo ""
echo "=== Cleaning up ==="
docker compose $COMPOSE_FILES down --volumes --remove-orphans

echo ""
echo "✓ Integration tests complete."
