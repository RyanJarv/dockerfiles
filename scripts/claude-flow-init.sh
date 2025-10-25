#!/bin/bash
# claude-flow-init - Enhanced initialization script for claude-flow
# Fixes upstream issues and Docker environment compatibility

set -e

CLAUDE_FLOW_VERSION="2.7.14"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Logging functions
log_info() {
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}[WARNING]${NC} $1"
}

log_error() {
    echo -e "${RED}[ERROR]${NC} $1"
}

# Function to get the actual installed version of a package
get_installed_version() {
    local package=$1
    if [ "$package" = "claude-flow" ] && command -v claude-flow >/dev/null 2>&1; then
        claude-flow --version 2>/dev/null && return
    fi
    local version=$(npm list -g "$package" 2>/dev/null | grep "$package@" | sed 's/.*@//' | head -1)
    if [ -z "$version" ]; then
        version=$(npx --yes "$package" --version 2>/dev/null || echo "")
    fi
    echo "$version"
}

run_claude_flow() {
    if command -v claude-flow >/dev/null 2>&1; then
        claude-flow "$@"
    else
        npx --yes "claude-flow@${CLAUDE_FLOW_VERSION}" "$@"
    fi
}

# Function to fix MCP server configuration
fix_mcp_config() {
    local mcp_config_file="$HOME/.config/claude/claude_desktop_config.json"

    log_info "Checking MCP server configuration..."

    if [ ! -f "$mcp_config_file" ]; then
        log_warning "MCP config file not found at $mcp_config_file"
        mkdir -p "$(dirname "$mcp_config_file")"
        echo '{"mcpServers":{}}' > "$mcp_config_file"
        log_success "Created new MCP config file"
    fi

    # Backup original config
    cp "$mcp_config_file" "${mcp_config_file}.backup.$(date +%s)"

    # Get installed versions
    log_info "Detecting installed package versions..."
    local claude_flow_version=$(get_installed_version "claude-flow")
    local ruv_swarm_version=$(get_installed_version "ruv-swarm")
    local flow_nexus_version=$(get_installed_version "flow-nexus")

    # Default to pinned claude-flow version if detection fails
    if [ -z "$claude_flow_version" ]; then
        claude_flow_version="@${CLAUDE_FLOW_VERSION}"
        log_warning "Could not detect claude-flow version, using ${claude_flow_version}"
    else
        claude_flow_version="@$claude_flow_version"
        log_success "Detected claude-flow version: $claude_flow_version"
    fi

    if [ -z "$ruv_swarm_version" ]; then
        ruv_swarm_version=""
        log_warning "Could not detect ruv-swarm version, using @latest"
    else
        ruv_swarm_version="@$ruv_swarm_version"
        log_success "Detected ruv-swarm version: $ruv_swarm_version"
    fi

    if [ -z "$flow_nexus_version" ]; then
        flow_nexus_version="@latest"
        log_warning "Could not detect flow-nexus version, using @latest"
    else
        flow_nexus_version="@$flow_nexus_version"
        log_success "Detected flow-nexus version: $flow_nexus_version"
    fi

    # Update MCP config with correct versions
    log_info "Updating MCP server configurations..."

    # Use jq to properly update JSON (with fallback to manual editing)
    if command -v jq &> /dev/null; then
        local tmp_file=$(mktemp)
        jq --arg cf_ver "$claude_flow_version" \
           --arg rs_ver "$ruv_swarm_version" \
           --arg fn_ver "$flow_nexus_version" \
           '.mcpServers."claude-flow".command = "claude-flow" |
            .mcpServers."claude-flow".args = ["mcp", "start"] |
            .mcpServers."ruv-swarm".command = "ruv-swarm" |
            .mcpServers."ruv-swarm".args = ["mcp", "start"] |
            .mcpServers."flow-nexus".command = "npx" |
            .mcpServers."flow-nexus".args = ["flow-nexus" + $fn_ver, "mcp", "start"]' \
           "$mcp_config_file" > "$tmp_file" && mv "$tmp_file" "$mcp_config_file"
        log_success "MCP configuration updated with correct versions"
    else
        log_warning "jq not found, MCP config may need manual adjustment"
    fi
}

# Function to create sparc-modes.json
create_sparc_modes() {
    local claude_dir="${1:-.claude}"
    local template_file="scripts/templates/sparc-modes.json"
    local target_file="$claude_dir/sparc-modes.json"

    log_info "Setting up SPARC modes configuration..."

    if [ -f "$target_file" ]; then
        log_warning "sparc-modes.json already exists, creating backup..."
        cp "$target_file" "${target_file}.backup.$(date +%s)"
    fi

    if [ -f "$template_file" ]; then
        cp "$template_file" "$target_file"
        log_success "Created sparc-modes.json from template"
    else
        log_error "Template file not found at $template_file"
        log_info "Attempting to download from claude-flow repository..."

        # Fallback: try to get from installed package or create minimal version
        if run_claude_flow sparc modes &>/dev/null; then
            log_success "SPARC modes available through claude-flow"
        else
            log_warning "Creating minimal sparc-modes.json"
            cat > "$target_file" << 'EOF'
{
  "customModes": [
    {
      "name": "SPARC Orchestrator",
      "slug": "sparc",
      "roleDefinition": "You are a SPARC methodology orchestrator. You break down complex software development tasks into systematic phases: Specification, Pseudocode, Architecture, Refinement, and Completion.",
      "customInstructions": "Follow the SPARC methodology to guide development:\n1. Specification - Define requirements and constraints\n2. Pseudocode - Design algorithms and logic flow\n3. Architecture - Plan system structure and components\n4. Refinement - Implement with iterative improvements\n5. Completion - Finalize, test, and document\n\nUse memory to track progress across phases.",
      "groups": ["read", "edit", "command", "mcp"],
      "source": "claude-flow built-in"
    }
  ]
}
EOF
        fi
    fi
}

# Function to verify MCP server connections
verify_mcp_connections() {
    log_info "Verifying MCP server connections..."

    local failed_servers=0

    # Test each server
    for server in "ruv-swarm" "claude-flow" "flow-nexus"; do
        log_info "Testing $server..."
        if claude mcp list 2>&1 | grep -q "$server.*✓ Connected"; then
            log_success "$server: Connected"
        else
            log_error "$server: Failed to connect"
            ((failed_servers++))
        fi
    done

    if [ $failed_servers -gt 0 ]; then
        log_warning "$failed_servers server(s) failed to connect"
        log_info "You may need to restart Claude desktop application or run: claude mcp restart"
        return 1
    else
        log_success "All MCP servers connected successfully"
        return 0
    fi
}

# Main initialization function
main() {
    log_info "Starting claude-flow initialization..."

    # Step 1: Run original claude-flow init
    log_info "Running claude-flow init..."
    if run_claude_flow init; then
        log_success "claude-flow init completed"
    else
        log_warning "claude-flow init had warnings (continuing...)"
    fi

    # Step 2: Create sparc-modes.json
    create_sparc_modes ".claude"

    # Step 3: Fix MCP configuration
    fix_mcp_config

    # Step 4: Verify connections
    log_info "Please restart Claude desktop application, then run this script with --verify"

    if [ "$1" == "--verify" ]; then
        sleep 2
        verify_mcp_connections
    fi

    log_success "Initialization complete!"
    echo ""
    log_info "Next steps:"
    echo "  1. Restart Claude desktop application"
    echo "  2. Run: $0 --verify"
    echo "  3. Test with: claude mcp list"
    echo "  4. Test SPARC: claude-flow sparc modes"
}

# Handle command-line arguments
case "${1:-}" in
    --verify)
        verify_mcp_connections
        ;;
    --fix-mcp)
        fix_mcp_config
        ;;
    --create-sparc)
        create_sparc_modes ".claude"
        ;;
    --help)
        echo "Usage: $0 [OPTION]"
        echo ""
        echo "Options:"
        echo "  (no args)       Run full initialization"
        echo "  --verify        Verify MCP connections only"
        echo "  --fix-mcp       Fix MCP configuration only"
        echo "  --create-sparc  Create sparc-modes.json only"
        echo "  --help          Show this help message"
        ;;
    *)
        main "$@"
        ;;
esac
