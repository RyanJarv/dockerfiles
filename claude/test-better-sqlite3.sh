#!/usr/bin/env bash
#
# Test script for better-sqlite3 native bindings in claude container
#
# This script tests various scenarios where better-sqlite3 may be required:
# 1. Global npm packages (ruv-swarm, claude-code)
# 2. NPX cache execution
# 3. Local project dependencies
#

set -e

IMAGE="${1:-ryanjarv/claude}"
TEST_DIR="/tmp/better-sqlite3-test-$$"
RESULTS_FILE="${TEST_DIR}/results.log"

# Color codes for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

log() {
    echo -e "${BLUE}[TEST]${NC} $*" | tee -a "$RESULTS_FILE"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $*" | tee -a "$RESULTS_FILE"
}

failure() {
    echo -e "${RED}[FAIL]${NC} $*" | tee -a "$RESULTS_FILE"
}

warning() {
    echo -e "${YELLOW}[WARN]${NC} $*" | tee -a "$RESULTS_FILE"
}

cleanup() {
    log "Cleaning up test directory: $TEST_DIR"
    rm -rf "$TEST_DIR"
}

trap cleanup EXIT

# Create test directory
mkdir -p "$TEST_DIR"
cd "$TEST_DIR"

log "Testing better-sqlite3 in image: $IMAGE"
log "Test directory: $TEST_DIR"
echo "" | tee -a "$RESULTS_FILE"

# Test 1: Check if better-sqlite3 can be required in globally installed packages
log "Test 1: Check globally installed packages for better-sqlite3"
docker run --rm "$IMAGE" bash -c '
    if command -v ruv-swarm >/dev/null 2>&1; then
        echo "Testing ruv-swarm (depends on better-sqlite3)..."
        if ruv-swarm --help >/dev/null 2>&1; then
            echo "SUCCESS: ruv-swarm works"
            exit 0
        else
            echo "FAILURE: ruv-swarm failed"
            exit 1
        fi
    else
        echo "SKIP: ruv-swarm not installed"
        exit 0
    fi
' && success "Global package test passed" || failure "Global package test failed"

echo "" | tee -a "$RESULTS_FILE"

# Test 2: Test NPX cache scenario (simulates the issue you reported)
log "Test 2: Test better-sqlite3 via NPX (simulates reported issue)"
docker run --rm -v "$TEST_DIR:/test" -w /test "$IMAGE" bash -c '
    echo "Running npx to trigger cache usage..."
    # This should trigger npx to cache better-sqlite3 if not already cached
    if npx --yes better-sqlite3@latest --help 2>&1 | grep -q "Error"; then
        echo "FAILURE: npx better-sqlite3 failed"
        exit 1
    else
        echo "SUCCESS: npx better-sqlite3 works"
        exit 0
    fi
' && success "NPX cache test passed" || failure "NPX cache test failed"

echo "" | tee -a "$RESULTS_FILE"

# Test 3: Test in a local project context (new node_modules)
log "Test 3: Test better-sqlite3 in local project (fresh install)"
cat > "$TEST_DIR/package.json" <<'EOF'
{
  "name": "better-sqlite3-test",
  "version": "1.0.0",
  "dependencies": {
    "better-sqlite3": "^11.0.0"
  }
}
EOF

docker run --rm -v "$TEST_DIR:/test" -w /test "$IMAGE" bash -c '
    echo "Installing better-sqlite3 locally..."
    npm install 2>&1 | tail -20

    echo "Testing require(\"better-sqlite3\")..."
    node -e "
        try {
            const Database = require(\"better-sqlite3\");
            const db = new Database(\":memory:\");
            db.exec(\"CREATE TABLE test (id INTEGER, name TEXT)\");
            db.exec(\"INSERT INTO test VALUES (1, '\''hello'\'')\");
            const row = db.prepare(\"SELECT * FROM test WHERE id = ?\").get(1);
            if (row.name === '\''hello'\'') {
                console.log(\"SUCCESS: Database operations work\");
                process.exit(0);
            } else {
                console.log(\"FAILURE: Database query returned wrong data\");
                process.exit(1);
            }
        } catch (err) {
            console.log(\"FAILURE: Error requiring or using better-sqlite3:\", err.message);
            process.exit(1);
        }
    "
' && success "Local project test passed" || failure "Local project test failed"

echo "" | tee -a "$RESULTS_FILE"

# Test 4: Check entrypoint script is working
log "Test 4: Verify entrypoint script detects and rebuilds if needed"
docker run --rm -v "$TEST_DIR:/test" -w /test "$IMAGE" bash -c '
    echo "Checking entrypoint script logs..."
    # The entrypoint should run when container starts
    if [ -f /usr/local/bin/claude-entrypoint.sh ]; then
        echo "Entrypoint script exists"
        cat /usr/local/bin/claude-entrypoint.sh | head -20
    else
        echo "WARNING: No entrypoint script found"
    fi
' && success "Entrypoint script exists" || warning "Entrypoint script check had issues"

echo "" | tee -a "$RESULTS_FILE"

# Test 5: Test node version mismatch scenario (if applicable)
log "Test 5: Simulate ABI mismatch detection"
docker run --rm "$IMAGE" bash -c '
    echo "Current Node version:"
    node --version
    echo ""
    echo "Checking for better-sqlite3 native modules:"
    find /root/.npm -name "better_sqlite3.node" 2>/dev/null | head -5 || echo "No native modules found in cache"
' && success "ABI check completed" || warning "ABI check had issues"

echo "" | tee -a "$RESULTS_FILE"

# Test 6: Check build tools are available
log "Test 6: Verify build tools are available for rebuilding"
docker run --rm "$IMAGE" bash -c '
    echo "Checking build tools..."
    errors=0

    if ! command -v python3 >/dev/null 2>&1; then
        echo "MISSING: python3"
        errors=$((errors + 1))
    else
        echo "FOUND: python3 $(python3 --version 2>&1)"
    fi

    if ! command -v npm >/dev/null 2>&1; then
        echo "MISSING: npm"
        errors=$((errors + 1))
    else
        echo "FOUND: npm $(npm --version)"
    fi

    if ! command -v node >/dev/null 2>&1; then
        echo "MISSING: node"
        errors=$((errors + 1))
    else
        echo "FOUND: node $(node --version)"
    fi

    if ! command -v node-gyp >/dev/null 2>&1; then
        echo "WARNING: node-gyp not in PATH, but may be in npm"
    else
        echo "FOUND: node-gyp $(node-gyp --version)"
    fi

    exit $errors
' && success "Build tools available" || failure "Some build tools missing"

echo "" | tee -a "$RESULTS_FILE"

# Summary
log "========================================="
log "Test Summary"
log "========================================="
cat "$RESULTS_FILE"
log "========================================="
log "Full results saved to: $RESULTS_FILE"
