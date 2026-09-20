# db-assistant-agent (OpenCode + GaussDB)

Isolated, read-only OpenCode agent for GaussDB diagnostics (centralized and
distributed) via MCP. Powered by Huawei Cloud MaaS (glm-5.2).

## Quick start (one command)

```bash
git clone <URL_OF_THIS_REPO> ~/db-assistant-agent
cd ~/db-assistant-agent
./setup.sh
```

`setup.sh` does everything interactively:

1. Installs **opencode** if not present
2. Installs **uv** (MCP runtime) if not present
3. Asks for your **Huawei Cloud MaaS API key**
4. Asks for the **mcp-opengauss** directory path
5. Asks for **GaussDB connection** details (read-only user)
6. Optionally **creates the read-only DB user** (admin credentials stay in the script, never stored or passed to the LLM)
7. Writes `.env`, sets up the isolated symlink + shell alias

Then run:
```bash
source ~/.bashrc   # or ~/.zshrc
db-assistant-agent
```

## Usage

- `opencode` → normal user environment (completely unchanged)
- `db-assistant-agent` → isolated environment, only this agent

## Security

- The database user must have only `SELECT`/`EXPLAIN` privileges — never an admin user.
- Admin credentials (if used during setup to create the read-only user) are used
  once in the terminal and immediately cleared — they are never written to any file
  and never passed to the LLM.
- All secrets live in `.env`, which is never committed (see `.gitignore`).
- The agent has `write`, `edit`, and `bash` tools disabled — it cannot modify files
  or run shell commands.

## Files

| File | Purpose |
|------|---------|
| `setup.sh` | One-command interactive installer |
| `install.sh` | Simpler installer (alias + symlink only, requires .env already configured) |
| `opencode/opencode.json` | OpenCode config with MaaS provider + MCP server (uses env vars) |
| `opencode/agents/db-assistant-agent.md` | The agent definition (read-only, model: maas/glm-5.2) |
| `create-read-only-user.sql` | SQL to create the restricted user (GaussDB all compatibility modes) |
| `.env.example` | Template for environment variables |

## Configuring the MCP server

The `opencode/opencode.json` references `mcp-opengauss` via `uv`. The path comes
from the `MCP_OPENGAUSS_DIR` env var in `.env`.

If you don't have `mcp-opengauss` yet:
```bash
mkdir -p ~/mcp-servers
git clone <URL_OF_MCP_OPENGAUSS> ~/mcp-servers/mcp-opengauss
```
