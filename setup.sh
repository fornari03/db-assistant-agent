#!/usr/bin/env bash
set -euo pipefail

# ── Colors ──
RED='\033[0;31m'; GREEN='\033[0;32m'; YELLOW='\033[1;33m'
BLUE='\033[0;34m'; BOLD='\033[1m'; NC='\033[0m'

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config-db-assistant"

info()  { echo -e "\n${BLUE}=== $1 ===${NC}"; }
ok()    { echo -e "  ${GREEN}✓${NC} $1"; }
warn_() { echo -e "  ${YELLOW}⚠${NC} $1"; }
fail()  { echo -e "  ${RED}✗${NC} $1"; }
prompt(){ printf "  ${BOLD}%s${NC}" "$1"; }

# Helper: find opencode in common locations
find_opencode() {
    command -v opencode 2>/dev/null && return 0
    [ -x "$HOME/.opencode/bin/opencode" ] && echo "$HOME/.opencode/bin/opencode" && return 0
    [ -x "/usr/local/bin/opencode" ] && echo "/usr/local/bin/opencode" && return 0
    return 1
}

echo ""
echo -e "${BOLD}  db-assistant-agent — One-Command Setup${NC}"
echo -e "  OpenCode + GaussDB (read-only) via MCP"
echo -e "  Model: Huawei Cloud MaaS (glm-5.2)"
echo ""

# ── Step 1: OpenCode ──
info "Step 1/6: OpenCode"

if OC_PATH="$(find_opencode 2>/dev/null)"; then
    ok "already installed ($("$OC_PATH" --version 2>&1 || echo 'unknown'))"
    # Ensure it's on PATH for the alias
    case ":$PATH:" in
        *":$(dirname "$OC_PATH"):"*) ;;
        *) export PATH="$(dirname "$OC_PATH"):$PATH" ;;
    esac
else
    warn_ "not found — installing..."
    # Try official installer
    if curl -fsSL https://opencode.ai/install | bash 2>&1; then
        ok "install script completed"
    else
        warn_ "official installer failed — trying npm..."
        if npm install -g opencode-ai 2>&1; then
            ok "installed via npm"
        else
            fail "could not install opencode automatically."
            echo ""
            echo "  Please install manually with one of:"
            echo "    curl -fsSL https://opencode.ai/install | bash"
            echo "    npm install -g opencode-ai"
            echo ""
            exit 1
        fi
    fi
    # Re-check after install (check all locations)
    export PATH="$HOME/.opencode/bin:$HOME/.local/bin:$PATH"
    if OC_PATH="$(find_opencode 2>/dev/null)"; then
        ok "found at: $OC_PATH"
    else
        fail "installed but not found in PATH. Please restart your shell and re-run."
        exit 1
    fi
fi

# ── Step 2: uv (MCP runtime) ──
info "Step 2/6: uv (MCP runtime)"

if command -v uv &>/dev/null; then
    ok "already installed"
else
    warn_ "not found — installing..."
    if curl -LsSf https://astral.sh/uv/install.sh | sh 2>&1; then
        export PATH="$HOME/.local/bin:$PATH"
        if command -v uv &>/dev/null; then
            ok "installed"
        else
            warn_ "installed but not in PATH — continuing (may need shell restart)"
        fi
    else
        warn_ "uv installation failed — you can install later:"
        warn_ "  curl -LsSf https://astral.sh/uv/install.sh | sh"
        warn_ "continuing anyway..."
    fi
fi

# ── Step 3: MaaS API key ──
info "Step 3/6: Huawei Cloud MaaS API key"

prompt "Enter your MaaS API key (hidden): "
read -s MAAS_API_KEY
echo ""
if [ -z "$MAAS_API_KEY" ]; then
    fail "MaaS API key is required."
    exit 1
fi
ok "API key set"

# ── Step 4: MCP server ──
info "Step 4/6: MCP server (mcp-opengauss)"

MCP_OPENGAUSS_DIR="$HOME/mcp-servers/mcp-opengauss"

if [ -d "$MCP_OPENGAUSS_DIR" ]; then
    ok "found: $MCP_OPENGAUSS_DIR"
else
    echo ""
    echo "  mcp-opengauss not found at $MCP_OPENGAUSS_DIR"
    echo ""
    echo "  Options:"
    echo "    1) Clone official mcp-opengauss from GitCode (recommended)"
    echo "    2) Clone from GitHub mirror (vincentsunx/mcp-openGauss)"
    echo "    3) Skip — I'll install it later"
    echo ""
    prompt "Choice [1-3] (default 1): "
    read -r MCP_CHOICE
    MCP_CHOICE="${MCP_CHOICE:-1}"

    case "$MCP_CHOICE" in
        1)
            info "Cloning official mcp-opengauss from GitCode"
            mkdir -p "$HOME/mcp-servers"
            if git clone https://gitcode.com/opengauss/mcp-opengauss.git "$MCP_OPENGAUSS_DIR" 2>&1; then
                ok "cloned to $MCP_OPENGAUSS_DIR"
            else
                warn_ "GitCode clone failed — trying GitHub mirror..."
                if git clone https://github.com/vincentsunx/mcp-openGauss.git "$MCP_OPENGAUSS_DIR" 2>&1; then
                    ok "cloned from GitHub mirror to $MCP_OPENGAUSS_DIR"
                else
                    fail "could not clone mcp-opengauss."
                    warn_ "install manually later and update MCP_OPENGAUSS_DIR in .env"
                fi
            fi
            ;;
        2)
            info "Cloning mcp-openGauss from GitHub"
            mkdir -p "$HOME/mcp-servers"
            if git clone https://github.com/vincentsunx/mcp-openGauss.git "$MCP_OPENGAUSS_DIR" 2>&1; then
                ok "cloned to $MCP_OPENGAUSS_DIR"
            else
                fail "clone failed — install manually later and update .env"
            fi
            ;;
        3)
            warn_ "skipped — the agent won't connect to GaussDB until you install mcp-opengauss"
            warn_ "after installing, update MCP_OPENGAUSS_DIR in .env"
            ;;
        *)
            warn_ "invalid choice — skipping (install mcp-opengauss later)"
            ;;
    esac
fi

# ── Step 5: GaussDB connection ──
info "Step 5/6: GaussDB connection (read-only user)"

prompt "Host [localhost]: "
read -r GAUSSDB_HOST
GAUSSDB_HOST="${GAUSSDB_HOST:-localhost}"

prompt "Port [8000]: "
read -r GAUSSDB_PORT
GAUSSDB_PORT="${GAUSSDB_PORT:-8000}"

prompt "Database name: "
read -r GAUSSDB_DBNAME
if [ -z "$GAUSSDB_DBNAME" ]; then
    fail "Database name is required."
    exit 1
fi

prompt "Read-only username [ai_agent_ro]: "
read -r GAUSSDB_USER
GAUSSDB_USER="${GAUSSDB_USER:-ai_agent_ro}"

prompt "Read-only user password (hidden): "
read -s GAUSSDB_PASSWORD
echo ""
if [ -z "$GAUSSDB_PASSWORD" ]; then
    fail "Password is required."
    exit 1
fi
ok "connection configured"

# ── Optional: Create DB user ──
echo ""
prompt "Create the read-only DB user now? Requires admin credentials (y/N): "
read -r CREATE_USER
if [[ "$CREATE_USER" =~ ^[Yy]$ ]]; then
    info "Creating read-only user"
    echo -e "  ${YELLOW}Admin credentials stay in this script only — never stored.${NC}"

    prompt "Admin username: "
    read -r ADMIN_USER
    prompt "Admin password (hidden): "
    read -s ADMIN_PASSWORD
    echo ""
    prompt "Schema name [public]: "
    read -r SCHEMA_NAME
    SCHEMA_NAME="${SCHEMA_NAME:-public}"

    SQL=$(cat <<SQLEOF
CREATE USER ${GAUSSDB_USER} PASSWORD '${GAUSSDB_PASSWORD}';
GRANT CONNECT ON DATABASE ${GAUSSDB_DBNAME} TO ${GAUSSDB_USER};
GRANT USAGE ON SCHEMA ${SCHEMA_NAME} TO ${GAUSSDB_USER};
GRANT SELECT ON ALL TABLES IN SCHEMA ${SCHEMA_NAME} TO ${GAUSSDB_USER};
ALTER DEFAULT PRIVILEGES IN SCHEMA ${SCHEMA_NAME} GRANT SELECT ON TABLES TO ${GAUSSDB_USER};
SQLEOF
)

    if command -v gsql &>/dev/null; then
        PGPASSWORD="$ADMIN_PASSWORD" gsql -h "$GAUSSDB_HOST" -p "$GAUSSDB_PORT" -U "$ADMIN_USER" -d "$GAUSSDB_DBNAME" -c "$SQL"
        ok "user created via gsql"
    elif command -v psql &>/dev/null; then
        PGPASSWORD="$ADMIN_PASSWORD" psql -h "$GAUSSDB_HOST" -p "$GAUSSDB_PORT" -U "$ADMIN_USER" -d "$GAUSSDB_DBNAME" -c "$SQL"
        ok "user created via psql"
    else
        warn_ "neither gsql nor psql found — SQL saved to create-user-now.sql"
        echo "$SQL" > "$REPO_DIR/create-user-now.sql"
        echo ""
        cat "$REPO_DIR/create-user-now.sql"
        echo ""
        warn_ "run the SQL above manually with admin credentials."
    fi

    # Clear admin credentials immediately
    ADMIN_USER=""
    ADMIN_PASSWORD=""
fi

# ── Step 6: Write .env + install ──
info "Step 6/6: Installation"

cat > "$REPO_DIR/.env" <<EOF
# Generated by setup.sh — DO NOT COMMIT
# Huawei Cloud MaaS
MAAS_API_KEY=${MAAS_API_KEY}

# MCP server
MCP_OPENGAUSS_DIR=${MCP_OPENGAUSS_DIR}

# GaussDB (read-only user)
GAUSSDB_HOST=${GAUSSDB_HOST}
GAUSSDB_PORT=${GAUSSDB_PORT}
GAUSSDB_USER=${GAUSSDB_USER}
GAUSSDB_PASSWORD=${GAUSSDB_PASSWORD}
GAUSSDB_DBNAME=${GAUSSDB_DBNAME}
EOF
ok ".env written"

# Symlink for XDG_CONFIG_HOME isolation
mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_DIR/opencode"
ln -s "$REPO_DIR/opencode" "$TARGET_DIR/opencode"
ok "symlink: $TARGET_DIR/opencode -> $REPO_DIR/opencode"

# Shell alias
SHELL_RC="$HOME/.zshrc"
[ "$(basename "${SHELL:-}")" = "bash" ] && SHELL_RC="$HOME/.bashrc"

ALIAS_LINE="alias db-assistant-agent='set -a; source \"$REPO_DIR/.env\"; set +a; XDG_CONFIG_HOME=\"$TARGET_DIR\" opencode'"

if ! grep -qF "db-assistant-agent" "$SHELL_RC" 2>/dev/null; then
    echo "$ALIAS_LINE" >> "$SHELL_RC"
    ok "alias added to $SHELL_RC"
else
    ok "alias already exists in $SHELL_RC"
fi

# Clear sensitive variables
MAAS_API_KEY=""; GAUSSDB_PASSWORD=""

# ── Done ──
echo ""
echo -e "${GREEN}${BOLD}  Setup complete!${NC}"
echo ""
echo "  Next steps:"
echo "    source $SHELL_RC"
echo "    db-assistant-agent"
echo ""
echo "  This opens OpenCode with ONLY the db-assistant-agent (isolated)."
echo "  Your regular 'opencode' command is unchanged."
echo ""
