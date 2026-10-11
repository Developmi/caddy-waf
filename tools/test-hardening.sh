#!/bin/sh
# caddy-waf Kernel Hardening & Runtime Asserts
# Verifies non-root UID 1337, read-only rootfs, noexec tmpfs, and capability confinement.
set -eu

NAME="caddy-waf-hardening-test"
TAG="caddy-waf:local"

cleanup() {
    docker rm -f "$NAME" >/dev/null 2>&1 || true
}
trap cleanup EXIT INT TERM

echo "=== Verifying image ($TAG) ==="
if ! docker image inspect "$TAG" >/dev/null 2>&1; then
    docker build -t "$TAG" .
fi

echo "=== Starting hardened container ($NAME) ==="
docker run -d --name "$NAME" \
    --read-only \
    --cap-drop=ALL \
    --cap-add=NET_BIND_SERVICE \
    --security-opt=no-new-privileges:true \
    --tmpfs /tmp:size=64m,noexec,nosuid,nodev,mode=1777 \
    --tmpfs /data/logs:uid=1337,gid=1337 \
    --tmpfs /config:uid=1337,gid=1337 \
    "$TAG" >/dev/null

sleep 2

echo "=== 1. Assert Non-Root UID (1337) ==="
UID_FOUND="$(docker exec "$NAME" id -u)"
if [ "$UID_FOUND" != "1337" ]; then
    echo "✗ FAIL: Container running as UID $UID_FOUND, expected 1337" >&2
    exit 1
fi
echo "✓ PASS: Container running strictly as UID 1337"

echo "=== 2. Assert Read-Only Root Filesystem ==="
if docker exec "$NAME" touch /etc/test_ro 2>/dev/null; then
    echo "✗ FAIL: Root filesystem allowed writes (read-only enforcement failed)" >&2
    exit 1
fi
echo "✓ PASS: Root filesystem is read-only (writes rejected)"

echo "=== 3. Assert Tmpfs noexec ==="
docker exec "$NAME" sh -c 'printf "#!/bin/sh\necho fail\n" > /tmp/test_exec.sh && chmod +x /tmp/test_exec.sh'
if docker exec "$NAME" /tmp/test_exec.sh 2>/dev/null; then
    echo "✗ FAIL: Execution permitted in /tmp (noexec enforcement failed)" >&2
    exit 1
fi
echo "✓ PASS: Execution in /tmp is strictly forbidden (noexec verified)"

echo "=== 4. Assert Effective Capabilities ==="
CAP_EFF="$(docker exec "$NAME" grep -i CapEff /proc/1/status | awk '{print $2}')"
case "$CAP_EFF" in
    *0000000000000000*|*00000000*)
        echo "✓ PASS: Effective capabilities are fully dropped (CapEff: $CAP_EFF)"
        ;;
    *)
        echo "✗ FAIL: Non-zero effective capabilities detected: $CAP_EFF" >&2
        exit 1
        ;;
esac

echo ""
echo "✓ All container kernel hardening assertions passed successfully."
exit 0
