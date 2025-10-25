# Troubleshooting: ONNX Runtime Embeddings Error

## Error Description

When running `claude-flow` commands that use ReasoningBank with semantic search, you may encounter:

```
Error: /onnxruntime_src/include/onnxruntime/core/common/logging/logging.h:371
Attempt to use DefaultLogger but none has been registered.

Something went wrong during model construction (most likely a missing operation). Using `wasm` as a fallback.
[Embeddings] Failed to initialize: no available backend found.
[Embeddings] Falling back to hash-based embeddings
```

## Root Cause

This error occurs when:

1. **npx installs fresh packages** instead of using the global binary
2. The npx-cached version at `/root/.npm/_npx/` has **ONNX Runtime native module issues**
3. **Native module ABI mismatch** between build environment and Node.js v25.0.0 runtime
4. ONNX Runtime initialization fails, falls back to WASM (which also fails), then to hash-based embeddings

## Impact

**Severity: Medium (Non-Critical but Degraded)**

- ✅ Commands complete successfully (memory operations work)
- ✅ Hash-based embeddings fallback functions
- ❌ **Loses semantic search capability** (less intelligent retrieval)
- ❌ **Slower/less accurate** memory retrieval
- ⚠️ Confusing error messages

## Why This Happens

The Docker container has:
- **Global binary**: `/usr/local/bin/claude-flow@2.7.4` (properly built with native modules)
- **Local wrapper**: `./claude-flow` (checks for global binary first)
- **Problem**: Some commands/scripts use `npx claude-flow@alpha` which:
  - Downloads version 2.7.23+ into npx cache
  - Has incompatible native module bindings
  - Fails ONNX Runtime initialization

## Solution

### Quick Fix

Always use the global binary or local wrapper:

```bash
# ✅ CORRECT: Use global binary directly
claude-flow memory store key "value"

# ✅ CORRECT: Use local wrapper (finds global binary)
./claude-flow memory store key "value"

# ❌ WRONG: npx installs fresh package
npx claude-flow@alpha memory store key "value"
```

### Permanent Fix

The following files have been updated to use the global binary:

1. **scripts/aliases.sh**: All aliases now use `claude-flow` (global) instead of `./claude-flow`
2. **claude-flow wrapper**: Fallback updated from `@2.7.14` → `@2.7.4`
3. **scripts/claude-flow-init.sh**: Configures MCP to use global binary

### For Scripts and Automation

If you're writing scripts that use claude-flow:

```bash
#!/bin/bash

# ✅ CORRECT: Use global binary
claude-flow memory store "key" "value"

# ✅ CORRECT: Check for global binary
if command -v claude-flow >/dev/null 2>&1; then
    claude-flow "$@"
else
    npx --yes claude-flow@2.7.4 "$@"
fi

# ❌ WRONG: Always use npx
npx claude-flow@alpha memory store "key" "value"
```

## Verification

After applying fixes, verify the setup:

```bash
# Check which binary is being used
which claude-flow
# Should show: /usr/local/bin/claude-flow

# Check version
claude-flow --version
# Should show: v2.7.4

# Test embeddings (should not show ONNX errors)
claude-flow memory store test_key "test value" 2>&1 | grep -i "onnx\|fallback"
# Should not show ONNX errors or fallback messages
```

## Technical Details

### Why Global Binary Works

The global `claude-flow@2.7.4` was:
1. Installed during Docker image build
2. Built with `better-sqlite3` using Python 3.11
3. Rebuilt for Node.js v25.0.0 ABI compatibility
4. Has properly initialized ONNX Runtime native modules

### Why npx Cache Fails

npx-cached packages:
1. Are installed on-demand into `/root/.npm/_npx/[hash]/`
2. May use pre-built binaries incompatible with Node.js v25.0.0
3. Don't get the Python 3.11 rebuild treatment
4. Have uninitialized ONNX Runtime loggers

### Embedding Modes

claude-flow supports three embedding backends (in priority order):

1. **ONNX Runtime** (best): Fast, accurate semantic embeddings via Xenova/all-MiniLM-L6-v2
2. **WASM** (fallback): Slower but compatible, uses WebAssembly
3. **Hash-based** (last resort): Fast but loses semantic understanding

The error shows ONNX failed, WASM failed, so it uses hash-based (lowest quality).

## Related Issues

- Native module compatibility: See `claude/TESTING-BETTER-SQLITE3.md`
- MCP server configuration: See `docs/claude-flow-init-guide.md`
- Global binary setup: See `CLAUDE.md` Runtime Baseline section

## Prevention

To prevent this error in the future:

1. **Always use global binaries** when available
2. **Avoid `npx` for frequently-used tools** in Docker
3. **Pin versions in fallbacks** to match global installs
4. **Rebuild native modules** after Node.js version changes
5. **Test embeddings** after package updates

## If Global Binary is Missing

If you don't have the global binary installed:

```bash
# Install globally with native module rebuild
npm install -g claude-flow@2.7.4
cd "$(npm root -g)/claude-flow"
PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3

# Or rebuild the Docker image
docker build --pull -t ryanjarv/claude claude/
```

## Alternative: Disable Embeddings

If you don't need semantic search, disable embeddings:

```bash
# Set environment variable
export REASONING_BANK_EMBEDDINGS=false

# Or use simple memory commands (no embeddings)
claude-flow memory set key value  # Simple key-value (no embeddings)
```

## Summary

**Problem**: npx installs fresh packages with broken ONNX Runtime native modules

**Solution**: Use the global binary at `/usr/local/bin/claude-flow@2.7.4`

**Status**: Fixed in scripts/aliases.sh and ./claude-flow wrapper

**Verification**: No ONNX errors when running memory commands
