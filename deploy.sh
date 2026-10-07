#!/usr/bin/env bash
# ==============================================================================
# One-Command Remote VPS Provisioner
# Usage: ./deploy.sh [user@]hostname-or-ip
# Example: ./deploy.sh root@203.0.113.10
# ==============================================================================
set -euo pipefail

TARGET="${1:-}"

if [ -z "$TARGET" ]; then
  echo "Usage: $0 [user@]hostname-or-ip" >&2
  echo "Example: $0 root@203.0.113.10" >&2
  exit 1
fi

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "==> [1/4] Preparing configuration payload..."
# Optionally bundle local .env and github_tokens.toml if present locally
if [ -f "$HOME/.omp/agent/.env" ] && [ ! -f "${SCRIPT_DIR}/configs/omp/.env" ]; then
  cp "$HOME/.omp/agent/.env" "${SCRIPT_DIR}/configs/omp/.env"
  chmod 600 "${SCRIPT_DIR}/configs/omp/.env"
fi

if [ -f "$HOME/.config/mise/github_tokens.toml" ] && [ ! -f "${SCRIPT_DIR}/configs/mise/github_tokens.toml" ]; then
  cp "$HOME/.config/mise/github_tokens.toml" "${SCRIPT_DIR}/configs/mise/github_tokens.toml"
  chmod 600 "${SCRIPT_DIR}/configs/mise/github_tokens.toml"
fi

echo "==> [2/4] Uploading provision bundle to ${TARGET}..."
ssh "$TARGET" 'rm -rf /tmp/vps-bootstrap && mkdir -p /tmp/vps-bootstrap'
scp -rq "${SCRIPT_DIR}/"* "${TARGET}:/tmp/vps-bootstrap/"

echo "==> [3/4] Executing remote bootstrap on ${TARGET}..."
# Using -t to allow interactive TUI/wizard over SSH
ssh -t "$TARGET" 'bash /tmp/vps-bootstrap/bootstrap.sh'

echo "==> [4/4] Cleaning up remote temporary installer files..."
ssh "$TARGET" 'rm -rf /tmp/vps-bootstrap'

echo "==> Setting up Tern remoting (if local Tern is installed)..."
if command -v tern &>/dev/null; then
  tern remote setup "$TARGET" || true
fi

echo "================================================================="
echo " VPS Provisioning Complete!"
echo "================================================================="
