# Scripts Directory

Utility scripts for claude-flow setup and maintenance.

## Available Scripts

### claude-flow-init.sh

Enhanced initialization wrapper for claude-flow that fixes upstream issues and Docker environment compatibility.

**Usage:**
```bash
# Full initialization
./scripts/claude-flow-init.sh

# Verify MCP connections
./scripts/claude-flow-init.sh --verify

# Fix MCP configuration only
./scripts/claude-flow-init.sh --fix-mcp

# Create sparc-modes.json only
./scripts/claude-flow-init.sh --create-sparc

# Show help
./scripts/claude-flow-init.sh --help
```

**Features:**
- ✅ Runs `claude-flow init`
- ✅ Creates `.claude/sparc-modes.json` from template
- ✅ Fixes MCP server version mismatches
- ✅ Auto-detects installed package versions
- ✅ Verifies server connections
- ✅ Creates backups before modifications

**Documentation:** [../docs/claude-flow-init-guide.md](../docs/claude-flow-init-guide.md)

### aliases.sh

Convenience shell aliases for claude-flow commands.

**Usage:**
```bash
# Load aliases
source scripts/aliases.sh

# Use aliases
cfi              # Run claude-flow-init
cfi-verify       # Verify MCP connections
cfi-fix          # Fix MCP configuration
cfi-sparc        # Create sparc-modes.json
sparc            # Run SPARC commands
mcp-list         # List MCP servers
claude-flow-status  # Full status check
```

**Available Aliases:**
- `claude-flow-init`, `cfi` - Run init script
- `cfi-verify` - Verify connections
- `cfi-fix` - Fix MCP config
- `cfi-sparc` - Create SPARC modes
- `sparc` - SPARC commands
- `sparc-modes` - List SPARC modes
- `sparc-tdd` - Run TDD workflow
- `mcp-list` - List MCP servers
- `mcp-restart` - Restart MCP servers
- `claude-flow-status` - Full status check function

## Templates

### templates/sparc-modes.json

Template file for SPARC methodology custom modes. Contains 13 pre-configured modes:

1. SPARC Orchestrator
2. Code Implementation
3. Test-Driven Development
4. System Architect
5. Debug & Troubleshoot
6. Documentation Writer
7. Code Reviewer
8. Refactoring Specialist
9. Integration Specialist
10. DevOps Engineer
11. Security Analyst
12. Performance Optimizer
13. Requirements Analyst

**Location:** Copied to `.claude/sparc-modes.json` during initialization

## Troubleshooting

### Script Won't Execute

```bash
# Make executable
chmod +x scripts/claude-flow-init.sh
chmod +x scripts/aliases.sh
```

### MCP Servers Not Connecting

```bash
# Fix configuration
./scripts/claude-flow-init.sh --fix-mcp

# Restart Claude desktop application

# Verify
./scripts/claude-flow-init.sh --verify
```

### Missing Dependencies

Ensure these are installed:
- Node.js v18+
- npm
- Claude desktop application
- jq (optional, for JSON processing)

```bash
# Check versions
node --version
npm --version
which claude
```

## File Structure

```
scripts/
├── README.md                    # This file
├── claude-flow-init.sh         # Main init script
├── aliases.sh                   # Shell aliases
└── templates/
    └── sparc-modes.json        # SPARC modes template
```

## Integration

### In Dockerfile

```dockerfile
COPY scripts/ /app/scripts/
RUN chmod +x /app/scripts/*.sh
RUN /app/scripts/claude-flow-init.sh
```

### In CI/CD

```yaml
- name: Initialize Claude Flow
  run: |
    ./scripts/claude-flow-init.sh
    ./scripts/claude-flow-init.sh --verify
```

### In Shell Profile

Add to `.bashrc`, `.zshrc`, or `.profile`:

```bash
# Load claude-flow aliases
if [ -f "$HOME/dockerfiles/scripts/aliases.sh" ]; then
    source "$HOME/dockerfiles/scripts/aliases.sh"
fi
```

## Contributing

When adding new scripts:

1. Make them executable: `chmod +x scripts/new-script.sh`
2. Add shebang: `#!/bin/bash`
3. Include help output: `--help` flag
4. Document in this README
5. Add to `CLAUDE.md` if user-facing

## Support

- **Init script issues**: Check [../docs/claude-flow-init-guide.md](../docs/claude-flow-init-guide.md)
- **Claude Flow**: https://github.com/ruvnet/claude-flow
- **Docker environment**: See main project README
