# Claude Flow Initialization Guide

## Overview

The `claude-flow-init.sh` script is a comprehensive wrapper around `claude-flow init` that fixes several upstream and Docker environment issues:

### Problems Solved

1. **Missing sparc-modes.json**: Upstream `claude-flow init` doesn't create `.claude/sparc-modes.json`
2. **MCP Version Mismatch**: MCP server configurations use incorrect package versions
3. **Connection Failures**: Global `claude-flow` MCP server setup avoids transient npx install issues

## Installation

The script is located at: `scripts/claude-flow-init.sh`

### Quick Start

```bash
# Full initialization
./scripts/claude-flow-init.sh

# After restarting Claude desktop
./scripts/claude-flow-init.sh --verify
```

## Usage

### Command Options

```bash
# Run full initialization (recommended)
./scripts/claude-flow-init.sh

# Verify MCP connections only
./scripts/claude-flow-init.sh --verify

# Fix MCP configuration only
./scripts/claude-flow-init.sh --fix-mcp

# Create sparc-modes.json only
./scripts/claude-flow-init.sh --create-sparc

# Show help
./scripts/claude-flow-init.sh --help
```

### What It Does

#### 1. Run Original Init
- Executes `claude-flow init` (falls back to pinned npx install if missing)
- Sets up basic `.claude/` directory structure

#### 2. Create sparc-modes.json
- Copies template from `scripts/templates/sparc-modes.json`
- Creates backup if file already exists
- Falls back to minimal config if template missing

#### 3. Fix MCP Configuration
- Detects installed package versions
- Updates `~/.config/claude/claude_desktop_config.json`
- Fixes version mismatches for:
  - `claude-flow@2.7.14`
  - `ruv-swarm`
  - `flow-nexus@latest`
- Creates backup before modifications

#### 4. Verify Connections
- Tests MCP server connectivity
- Reports status for each server
- Provides troubleshooting guidance

## Technical Details

### Version Detection

The script automatically detects installed package versions:

```bash
# Checks npm global list
npm list -g "package-name"

# Falls back to npx version command
npx --yes package-name --version

# Uses sensible defaults if detection fails
claude-flow: @2.7.14
ruv-swarm: @latest
flow-nexus: @latest
```

### MCP Configuration

Updates `claude_desktop_config.json` structure:

```json
{
  "mcpServers": {
    "claude-flow": {
      "command": "claude-flow",
      "args": ["mcp", "start"]
    },
    "ruv-swarm": {
      "command": "ruv-swarm",
      "args": ["mcp", "start"]
    },
    "flow-nexus": {
      "command": "npx",
      "args": ["flow-nexus@latest", "mcp", "start"]
    }
  }
}
```

### SPARC Modes

Creates 13 custom modes:
- SPARC Orchestrator
- Code Implementation
- Test-Driven Development
- System Architect
- Debug & Troubleshoot
- Documentation Writer
- Code Reviewer
- Refactoring Specialist
- Integration Specialist
- DevOps Engineer
- Security Analyst
- Performance Optimizer
- Requirements Analyst

## Troubleshooting

### MCP Server Won't Connect

```bash
# 1. Fix configuration
./scripts/claude-flow-init.sh --fix-mcp

# 2. Restart Claude desktop

# 3. Verify connections
./scripts/claude-flow-init.sh --verify

# 4. Check status manually
claude mcp list
```

### sparc-modes.json Missing

```bash
# Recreate from template
./scripts/claude-flow-init.sh --create-sparc

# Verify it was created
ls -la .claude/sparc-modes.json

# Test SPARC modes
claude-flow sparc modes
```

### Version Detection Fails

The script uses safe defaults:
- `claude-flow@2.7.14` - Pinned stable version
- `ruv-swarm@latest` - Latest stable
- `flow-nexus@latest` - Latest stable

You can manually edit `~/.config/claude/claude_desktop_config.json` if needed.

### Docker Environment Issues

In Docker containers:
1. Ensure Node.js is properly installed
2. NPM packages may need global installation
3. MCP config path: `$HOME/.config/claude/`

## Integration with Existing Setup

### Running After Manual Init

If you've already run `claude-flow init`:

```bash
# Just fix what's missing
./scripts/claude-flow-init.sh --create-sparc
./scripts/claude-flow-init.sh --fix-mcp
```

### Automated Setup

Add to your Dockerfile or setup script:

```bash
# In Dockerfile
RUN ./scripts/claude-flow-init.sh

# Or in setup script
./scripts/claude-flow-init.sh && \
  echo "Remember to restart Claude desktop!"
```

## File Locations

```
dockerfiles/
├── scripts/
│   ├── claude-flow-init.sh       # Main init script
│   └── templates/
│       └── sparc-modes.json      # SPARC modes template
├── .claude/
│   ├── sparc-modes.json          # Created by script
│   └── ...                        # Other claude-flow files
└── ~/.config/claude/
    └── claude_desktop_config.json # MCP configuration
```

## Maintenance

### Updating Templates

Edit `scripts/templates/sparc-modes.json` to modify SPARC modes:

```bash
# After editing template
./scripts/claude-flow-init.sh --create-sparc
```

### Backups

The script creates timestamped backups:
- `.claude/sparc-modes.json.backup.[timestamp]`
- `~/.config/claude/claude_desktop_config.json.backup.[timestamp]`

### Logs

All operations log to stdout with color-coded messages:
- 🔵 `[INFO]` - Informational messages
- 🟢 `[SUCCESS]` - Successful operations
- 🟡 `[WARNING]` - Non-critical issues
- 🔴 `[ERROR]` - Critical failures

## Best Practices

1. **Always restart Claude desktop** after running init
2. **Run verification** with `--verify` after restart
3. **Keep backups** of working configurations
4. **Check MCP status** regularly with `claude mcp list`
5. **Update packages** periodically for bug fixes

## Related Commands

```bash
# Claude MCP management
claude mcp list                    # List all MCP servers
claude mcp restart                 # Restart MCP servers
claude mcp add <name> <command>    # Add new server

# Claude Flow commands
claude-flow sparc modes            # List SPARC modes
claude-flow sparc run <mode>       # Run SPARC mode
claude-flow mcp start              # Start MCP server

# Verification
ruv-swarm mcp start                # Test ruv-swarm
npx flow-nexus mcp start           # Test flow-nexus
```

## Support

For issues with:
- **This script**: Check logs, verify Node.js installation
- **claude-flow upstream**: https://github.com/ruvnet/claude-flow/issues
- **MCP servers**: Restart Claude desktop and check `claude mcp list`

## Changelog

### Version 1.0.0
- Initial release
- Automatic version detection
- MCP configuration fixing
- SPARC modes template
- Connection verification
- Colorized logging
- Backup creation

## Future Enhancements

Potential improvements:
- [ ] Auto-detection of Docker environment
- [ ] Interactive mode with prompts
- [ ] Custom mode addition wizard
- [ ] Health check monitoring
- [ ] Automatic package updates
- [ ] Configuration validation
- [ ] Rollback capability
