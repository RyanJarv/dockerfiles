# Claude Container

Docker image with Claude Code CLI, claude-flow, and ruv-swarm with properly configured better-sqlite3 native bindings.

## Quick Start

```bash
# Build the image
docker buildx build -t ryanjarv/claude -f claude/Dockerfile ./claude

# Test it works
./claude/test-ruv-swarm.sh

# Use via shell functions
source ../sh_functions
claude --help
claude-flow --help
ruv-swarm --help
```

## What's Included

- **@anthropic-ai/claude-code** - Claude CLI
- **claude-flow@alpha** - Claude Flow orchestration
- **ruv-swarm** - Agent swarm tooling
- **better-sqlite3** - Prebuilt with native bindings for Node v25.0.0

## Components

### Dockerfile
- Installs Node.js, Python, and build tools
- Installs Claude, claude-flow, and ruv-swarm globally
- Prebuilds better-sqlite3 with proper PYTHON env var
- Attempts to prebuild npx cache (non-blocking)

### claude-entrypoint.sh
- Runtime detection and rebuild of better-sqlite3 when needed
- Scans for ABI mismatches in:
  - Current directory and parent directories
  - NPX cache (~/.npm/_npx)
- Auto-rebuilds with correct PYTHON path
- Provides verbose error output for debugging

## Testing

### Quick Test (Recommended)
```bash
./test-ruv-swarm.sh
```
Simply runs `ruv-swarm --help` which depends on better-sqlite3.

### Comprehensive Testing
```bash
# Full test suite (runs outside container)
./test-better-sqlite3.sh

# In-container tests
docker run --rm -it -v "$PWD:/test-scripts" ryanjarv/claude bash /test-scripts/test-in-container.sh
```

### Manual Testing
```bash
# Start a shell in the container
source ../sh_functions
claude.shell

# Inside container:
ruv-swarm --help
node -e "require('better-sqlite3')"
```

See [TESTING-BETTER-SQLITE3.md](TESTING-BETTER-SQLITE3.md) for detailed testing documentation.

## Troubleshooting

### Build Fails: `/root/.npm/_npx` not found
The Dockerfile wraps both npx and find commands in error-tolerant subshells. Ensure you have the latest version:
```bash
git pull origin main
docker buildx build -t ryanjarv/claude -f claude/Dockerfile ./claude
```

### Runtime: "Cannot find module" for better_sqlite3.node
This should be automatically fixed by the entrypoint script. If not:

1. Check entrypoint logs for rebuild attempts
2. Verify build tools are present:
   ```bash
   docker run --rm ryanjarv/claude bash -c 'python3 --version && npm --version'
   ```
3. Manually rebuild:
   ```bash
   docker run --rm -it ryanjarv/claude bash
   cd /usr/local/lib/node_modules/ruv-swarm
   PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3
   ```

### MCP: "spawn ruv-swarm ENOENT"
If Claude Code's MCP server can't find ruv-swarm:

1. Verify ruv-swarm is in PATH:
   ```bash
   docker run --rm ryanjarv/claude bash -c 'which ruv-swarm'
   ```
   Should output: `/usr/local/bin/ruv-swarm` or `/usr/bin/ruv-swarm`

2. If missing, rebuild the image with the latest Dockerfile which includes the symlink step

### Tests Still Failing
See the detailed debugging section in [TESTING-BETTER-SQLITE3.md](TESTING-BETTER-SQLITE3.md#debugging-tips).

## Files

- **Dockerfile** - Image build instructions
- **claude-entrypoint.sh** - Runtime better-sqlite3 rebuild logic
- **test-ruv-swarm.sh** - Quick validation test
- **test-better-sqlite3.sh** - Comprehensive test suite
- **test-in-container.sh** - In-container test script
- **quick-test.sh** - NPX-focused tests
- **run-test.sh** - Test wrapper
- **TESTING-BETTER-SQLITE3.md** - Complete testing documentation

## Recent Changes

### 2025 Updates
- Fixed ruv-swarm MCP server: Added symlink to /usr/local/bin so MCP can spawn ruv-swarm
- Fixed Dockerfile build error: wrapped npx and find commands in error-tolerant subshells
- Enhanced entrypoint script: added PYTHON env var, broader error detection, verbose output
- Created comprehensive test suite for better-sqlite3 validation
- Documented testing strategy and troubleshooting steps

See git log for detailed commit history.
