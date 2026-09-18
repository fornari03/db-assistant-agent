# db-assistant-agent (OpenCode + GaussDB)

Isolated, read-only OpenCode agent for GaussDB diagnostics (centralized and
distributed) via MCP.

## Local installation

```bash
git clone <URL_OF_THIS_REPO> ~/projects/db-assistant-agent-opencode
cd ~/projects/db-assistant-agent-opencode
cp .env.example .env   # fill in the restricted user credentials
./install.sh
```

## Usage

- `opencode` → normal user environment (unchanged)
- `db-assistant-agent` → isolated environment, only this agent

## Security

The database user used here must have only `SELECT`/`EXPLAIN` privileges. Never
point this agent at an admin user. Credentials live in `.env`, which is never
committed (see `.gitignore`).

## Configuring the `mcp-opengauss` MCP server

The `opencode/opencode.json` file references the `mcp-opengauss` MCP server via `uv`.
Adjust the `--directory` path to the real location where `mcp-opengauss` is installed.

If you don't have `mcp-opengauss` yet:

```bash
# option 1: clone to ~/mcp-servers
mkdir -p ~/mcp-servers
git clone <URL_OF_MCP_OPENGAUSS> ~/mcp-servers/mcp-opengauss

# then update the path in opencode/opencode.json:
#   "command": ["uv", "--directory", "~/mcp-servers/mcp-opengauss", "run", "server.py"]
```

If you don't have `uv` installed, install it with `curl -LsSf https://astral.sh/uv/install.sh | sh`.
