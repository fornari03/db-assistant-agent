#!/usr/bin/env bash
set -euo pipefail

REPO_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TARGET_DIR="$HOME/.config-db-assistant"

mkdir -p "$TARGET_DIR"
rm -rf "$TARGET_DIR/opencode"
ln -s "$REPO_DIR/opencode" "$TARGET_DIR/opencode"

if [ ! -f "$REPO_DIR/.env" ]; then
  echo "WARNING: .env not found. Copy .env.example to .env and fill it in before use."
fi

SHELL_RC="$HOME/.zshrc"
[ "$(basename "${SHELL:-}")" = "bash" ] && SHELL_RC="$HOME/.bashrc"

ALIAS_LINE="alias db-assistant-agent='set -a; source \"$REPO_DIR/.env\"; set +a; XDG_CONFIG_HOME=\"$TARGET_DIR\" opencode'"

if ! grep -qF "db-assistant-agent" "$SHELL_RC" 2>/dev/null; then
  echo "$ALIAS_LINE" >> "$SHELL_RC"
  echo "Alias added to $SHELL_RC. Run: source $SHELL_RC"
else
  echo "Alias already exists in $SHELL_RC — not duplicated."
fi
