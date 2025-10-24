#!/usr/bin/env bash
#
# Simple test: Just run ruv-swarm directly to see if better-sqlite3 works
# This is the simplest reproduction of the issue
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Testing ruv-swarm (which depends on better-sqlite3)"
echo ""

if command -v docker >/dev/null 2>&1; then
    echo "=== Running ruv-swarm --help ==="
    docker run --rm \
        --entrypoint bash \
        ryanjarv/claude \
        -c 'ruv-swarm --help' 2>&1 | tee /tmp/ruv-swarm-test.log

    echo ""

    if grep -qi "cannot find module\|error" /tmp/ruv-swarm-test.log; then
        echo "❌ FAILED: ruv-swarm failed (likely better-sqlite3 issue)"
        echo ""
        echo "Error details:"
        grep -i "error\|cannot" /tmp/ruv-swarm-test.log || cat /tmp/ruv-swarm-test.log
        exit 1
    else
        echo "✅ SUCCESS: ruv-swarm works (better-sqlite3 is loading correctly)"
        exit 0
    fi
else
    echo "Docker not available."
    echo ""
    echo "To test manually:"
    echo "  1. source $REPO_ROOT/sh_functions"
    echo "  2. ruv-swarm --help"
    echo ""
    echo "If you see 'Cannot find module' errors, the issue exists."
    exit 2
fi
