# Testing Strategy for better-sqlite3 Native Bindings

## Problem Summary

The `better-sqlite3` npm package requires native bindings (`.node` files) that must be compiled for the specific Node.js version and architecture. When these bindings are missing or compiled for the wrong version, you get errors like:

```
Cannot find module '..../better_sqlite3.node'
```

## Why This Issue Occurs

1. **NPX Cache**: When using `npx`, modules are cached in `~/.npm/_npx/`. If better-sqlite3 is installed without proper build tools or the wrong Node version, the native bindings won't work.

2. **Node ABI Version Mismatch**: Native modules are tied to Node's ABI (Application Binary Interface) version. Node v25.0.0 requires specific bindings.

3. **Build Requirements**: better-sqlite3 needs:
   - C++ compiler (g++)
   - Python (for node-gyp)
   - node-gyp
   - Build tools (make, etc.)

## Testing Strategy

### Simplest Test - ruv-swarm (RECOMMENDED)

The easiest way to test is to simply run `ruv-swarm`, which depends on better-sqlite3:

```bash
./claude/test-ruv-swarm.sh
```

Or manually using the shell function:

```bash
source sh_functions
ruv-swarm --help
```

If you see "Cannot find module" errors for better_sqlite3.node, the issue exists.

### Quick Test (Reproduces the Issue)

**Option 1: Using the test wrapper**

```bash
./claude/run-test.sh
```

This runs the test inside the container using the in-container test script.

**Option 2: Manual shell access**

```bash
# Source the shell functions
source sh_functions

# Start a shell in the container
claude.shell

# Inside the container, run:
cd /test-scripts
./test-in-container.sh
```

**Option 3: Direct docker (if docker is available)**

```bash
./claude/quick-test.sh
```

This simulates the exact scenario you reported - using npx to run better-sqlite3.

### Comprehensive Test Suite

Run the full test suite to validate all scenarios:

```bash
./claude/test-better-sqlite3.sh [image-name]
```

This tests:
1. **Global packages** - Checks if ruv-swarm (which depends on better-sqlite3) works
2. **NPX cache** - Tests the exact error scenario reported
3. **Local projects** - Tests fresh npm install in a new project
4. **Entrypoint script** - Verifies the rebuild logic runs correctly
5. **ABI detection** - Checks Node version and native module compatibility
6. **Build tools** - Ensures all required build tools are present

### Manual Testing

You can also test manually:

```bash
# Start a shell in the container
docker run --rm -it ryanjarv/claude bash

# Test 1: Try using npx
npx --yes better-sqlite3@latest --help

# Test 2: Check if rebuild works
cd ~/.npm/_npx/*/node_modules/better-sqlite3
PYTHON=/usr/local/bin/python3.11 npm rebuild better-sqlite3

# Test 3: Check global packages
ruv-swarm --help

# Test 4: Create a test project
mkdir /tmp/test && cd /tmp/test
npm init -y
npm install better-sqlite3
node -e "console.log(require('better-sqlite3'))"
```

## Validating the Fix

After applying a fix (Dockerfile or entrypoint changes):

1. **Rebuild the image**:
   ```bash
   docker buildx build -t ryanjarv/claude -f claude/Dockerfile ./claude
   ```

2. **Run quick test**:
   ```bash
   ./claude/quick-test.sh
   ```

3. **Run full test suite**:
   ```bash
   ./claude/test-better-sqlite3.sh
   ```

4. **Test with actual usage**:
   ```bash
   # Use the claude() function from sh_functions
   source sh_functions
   claude --help
   ```

## Expected Results

### ✅ Success Criteria

- NPX can run better-sqlite3 without errors
- ruv-swarm works correctly (it uses better-sqlite3)
- Fresh npm install of better-sqlite3 works
- Database operations succeed (CREATE, INSERT, SELECT)
- No "Cannot find module" errors

### ❌ Failure Indicators

- "Cannot find module" errors for better_sqlite3.node
- "ERR_DLOPEN_FAILED" errors
- "NODE_MODULE_VERSION mismatch" errors
- ruv-swarm commands fail

## Common Issues and Solutions

### Issue: Native bindings not found in npx cache

**Solution**: Pre-build better-sqlite3 during Docker image build with proper flags:
```dockerfile
RUN PYTHON=/usr/local/bin/python3.11 npm install -g better-sqlite3 --build-from-source
```

### Issue: Entrypoint doesn't rebuild correctly

**Solution**: Ensure entrypoint script:
- Sets `PYTHON` environment variable
- Scans all potential node_modules locations
- Has proper error detection and logging

### Issue: Build tools missing

**Solution**: Install all required dependencies:
```dockerfile
RUN apt-get install -y build-essential python3-dev
```

## Debugging Tips

1. **Check Node version**: `node --version`
2. **Find native modules**: `find ~/.npm -name "better_sqlite3.node"`
3. **Check module info**: `node -p "process.versions.modules"` (shows ABI version)
4. **Verbose npm rebuild**: `npm rebuild better-sqlite3 --verbose`
5. **Test require directly**: `node -e "require('better-sqlite3')"`

## References

- better-sqlite3 GitHub: https://github.com/WiseLibs/better-sqlite3
- Node ABI versions: https://nodejs.org/en/download/releases/
- node-gyp guide: https://github.com/nodejs/node-gyp
