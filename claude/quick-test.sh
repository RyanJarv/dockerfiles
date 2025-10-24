#!/usr/bin/env bash
#
# Quick test for better-sqlite3 issue
# Run this to quickly reproduce the error you're seeing
#

set -e

IMAGE="${1:-ryanjarv/claude}"

echo "Quick test for better-sqlite3 native bindings issue"
echo "Image: $IMAGE"
echo ""

echo "=== Test 1: Direct require of better-sqlite3 via NPX ==="
docker run --rm --entrypoint bash "$IMAGE" -c '
    set -x
    # Try to require better-sqlite3 via npx - this should trigger the native binding load
    npx --yes -p better-sqlite3 node -e "require('\''better-sqlite3'\'')"
' 2>&1 | tee /tmp/quick-test-output.log

echo ""
echo "=== Test 2: Test ruv-swarm (uses better-sqlite3) ==="
docker run --rm --entrypoint bash "$IMAGE" -c '
    set -x
    # ruv-swarm depends on better-sqlite3
    if command -v ruv-swarm >/dev/null 2>&1; then
        ruv-swarm --help 2>&1 || true
    else
        echo "ruv-swarm not found"
    fi
' 2>&1 | tee -a /tmp/quick-test-output.log

if grep -q "Cannot find module" /tmp/quick-test-output.log; then
    echo ""
    echo "❌ ISSUE REPRODUCED: better-sqlite3 native binding not found"
    echo ""
    echo "Error details:"
    grep -A5 "Cannot find module" /tmp/quick-test-output.log | head -20
    exit 1
else
    echo ""
    echo "✅ SUCCESS: No module errors detected"
    exit 0
fi
