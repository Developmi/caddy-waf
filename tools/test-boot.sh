#!/bin/sh
# caddy-waf Bare-Boot Regression Test
# Verifies the baked default config boots as UID 1337 with no mounts or ports:
# catches the case where Coraza provisions /data/logs/coraza-audit.log as root
# during build, which would make a bare `docker run` fail (permission denied).
set -eu

NAME="caddy-waf-boot-test"
TAG="caddy-waf:local"
TIMEOUT=120
INTERVAL=2

cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo "=== Building image ($TAG) ==="
docker build -t "$TAG" .

echo "=== Starting bare container ($NAME) ==="
docker run -d --name "$NAME" "$TAG" >/dev/null

echo "=== Waiting for health (timeout ${TIMEOUT}s, interval ${INTERVAL}s) ==="
elapsed=0
while [ "$elapsed" -lt "$TIMEOUT" ]; do
    status="$(docker inspect -f '{{.State.Health.Status}}' "$NAME" 2>/dev/null || true)"
    case "$status" in
        healthy)
            echo ""
            echo "✓ PASS: bare container is healthy"
            exit 0
            ;;
        unhealthy)
            break
            ;;
        *)
            sleep "$INTERVAL"
            elapsed=$((elapsed + INTERVAL))
            ;;
    esac
done

echo ""
echo "✗ FAIL: bare container did not become healthy"
echo "=== docker logs $NAME ==="
docker logs "$NAME" || true
exit 1
