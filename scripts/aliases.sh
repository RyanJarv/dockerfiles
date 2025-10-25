#!/bin/bash
# Convenience aliases for claude-flow and related tools

# Claude Flow Init
alias claude-flow-init='./scripts/claude-flow-init.sh'
alias cfi='./scripts/claude-flow-init.sh'

# Claude Flow Init Commands
alias cfi-verify='./scripts/claude-flow-init.sh --verify'
alias cfi-fix='./scripts/claude-flow-init.sh --fix-mcp'
alias cfi-sparc='./scripts/claude-flow-init.sh --create-sparc'

# Claude Flow SPARC (use global binary)
alias sparc='claude-flow sparc'
alias sparc-modes='claude-flow sparc modes'
alias sparc-tdd='claude-flow sparc tdd'

# MCP Management
alias mcp-list='claude mcp list'
alias mcp-restart='claude mcp restart'

# Quick status check
claude-flow-status() {
    echo "🔍 Checking Claude Flow status..."
    echo ""
    echo "📦 MCP Servers:"
    claude mcp list
    echo ""
    echo "📝 SPARC Modes:"
    if [ -f ".claude/sparc-modes.json" ]; then
        echo "✅ sparc-modes.json exists"
        claude-flow sparc modes 2>/dev/null || echo "⚠️  SPARC command may need verification"
    else
        echo "❌ sparc-modes.json missing - run: claude-flow-init --create-sparc"
    fi
}

# Add to shell
echo "✨ Claude Flow aliases loaded!"
echo "   cfi          - Run claude-flow-init"
echo "   cfi-verify   - Verify MCP connections"
echo "   cfi-fix      - Fix MCP configuration"
echo "   cfi-sparc    - Create sparc-modes.json"
echo "   sparc        - Run SPARC command"
echo "   mcp-list     - List MCP servers"
echo ""
echo "💡 Run 'claude-flow-status' for full status check"
