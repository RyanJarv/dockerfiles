#!/usr/bin/env bash
#
# Run this script INSIDE the claude container to test better-sqlite3
# Usage: docker run --rm -it ryanjarv/claude bash /path/to/test-in-container.sh
#

set -e

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[TEST]${NC} $*"
}

success() {
    echo -e "${GREEN}[PASS]${NC} $*"
}

failure() {
    echo -e "${RED}[FAIL]${NC} $*"
}

TESTS_PASSED=0
TESTS_FAILED=0

run_test() {
    local test_name="$1"
    local test_command="$2"

    log "Running: $test_name"
    if eval "$test_command" >/dev/null 2>&1; then
        success "$test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        failure "$test_name"
        TESTS_FAILED=$((TESTS_FAILED + 1))
        # Show error for failed test
        echo "  Error output:"
        eval "$test_command" 2>&1 | head -10 | sed 's/^/    /'
    fi
    echo ""
}

log "Testing better-sqlite3 in container"
log "Node version: $(node --version)"
log "NPM version: $(npm --version)"
echo ""

# Test 1: Try to load better-sqlite3 from global node_modules
log "=== Test 1: Load better-sqlite3 from global packages ==="
run_test "Require better-sqlite3 from global" \
    "node -e \"require('better-sqlite3')\""

# Test 2: NPX with fresh install
log "=== Test 2: NPX fresh install and require ==="
run_test "NPX install and require better-sqlite3" \
    "npx --yes -p better-sqlite3 node -e \"require('better-sqlite3')\""

# Test 3: Test ruv-swarm if available
log "=== Test 3: ruv-swarm (depends on better-sqlite3) ==="
if command -v ruv-swarm >/dev/null 2>&1; then
    run_test "ruv-swarm --help" \
        "ruv-swarm --help"
else
    log "Skipping: ruv-swarm not installed"
    echo ""
fi

# Test 4: Create a test database
log "=== Test 4: Create and query an in-memory database ==="
run_test "Database operations" \
    "node -e \"
const Database = require('better-sqlite3');
const db = new Database(':memory:');
db.exec('CREATE TABLE test (id INTEGER, name TEXT)');
db.exec('INSERT INTO test VALUES (1, \\\\'hello\\\\')');
const row = db.prepare('SELECT * FROM test WHERE id = ?').get(1);
if (row.name !== 'hello') throw new Error('Query failed');
console.log('Database test passed');
\""

# Test 5: Check for native modules
log "=== Test 5: Find native module files ==="
echo "Looking for better_sqlite3.node files:"
find /root/.npm -name "better_sqlite3.node" -type f 2>/dev/null | head -5 || echo "  No files found in ~/.npm"
find /usr/local/lib/node_modules -name "better_sqlite3.node" -type f 2>/dev/null | head -5 || echo "  No files found in global node_modules"
echo ""

# Test 6: Check build tools
log "=== Test 6: Verify build tools ==="
for tool in python3 node npm gcc g++ make; do
    if command -v "$tool" >/dev/null 2>&1; then
        success "Found: $tool"
    else
        failure "Missing: $tool"
    fi
done
echo ""

# Summary
log "========================================="
log "Test Summary"
log "========================================="
success "Tests passed: $TESTS_PASSED"
if [ $TESTS_FAILED -gt 0 ]; then
    failure "Tests failed: $TESTS_FAILED"
    exit 1
else
    success "All tests passed!"
    exit 0
fi
