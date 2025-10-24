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

echo "=== Test: NPX better-sqlite3 (reproduces your reported error) ==="
docker run --rm "$IMAGE" bash -c '
    set -x
    npx --yes better-sqlite3@latest --help
' 2>&1 | tee /tmp/quick-test-output.log

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
