#!/usr/bin/env bash
#
# Wrapper script to run tests using the claude container
# This script uses the shell functions defined in sh_functions
#

set -e

SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
REPO_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

echo "Testing better-sqlite3 in claude container"
echo "Repository root: $REPO_ROOT"
echo ""

# Method 1: Using docker directly with entrypoint override
echo "=== Method 1: Direct docker test (bypassing entrypoint) ==="
if command -v docker >/dev/null 2>&1; then
    docker run --rm \
        --entrypoint bash \
        -v "$SCRIPT_DIR:/test-scripts" \
        ryanjarv/claude \
        /test-scripts/test-in-container.sh
else
    echo "Docker not available, skipping..."
fi

echo ""
echo "=== Method 2: Test using shell function ==="
echo "To test using the claude shell function from sh_functions:"
echo ""
echo "  source $REPO_ROOT/sh_functions"
echo "  claude.shell"
echo "  # Then inside the container:"
echo "  cd /test-scripts"
echo "  ./test-in-container.sh"
echo ""
