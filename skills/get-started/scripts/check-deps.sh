#!/usr/bin/env bash
# Check system dependencies for Iterator TV local development.
# Outputs a status line for each dependency: PASS, FAIL, or WARN.

set -uo pipefail

RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

pass=0
fail=0
warn=0

check() {
  local name="$1" status="$2" detail="$3"
  case "$status" in
    PASS) echo -e "${GREEN}[PASS]${NC} $name — $detail"; ((pass++)) ;;
    FAIL) echo -e "${RED}[FAIL]${NC} $name — $detail"; ((fail++)) ;;
    WARN) echo -e "${YELLOW}[WARN]${NC} $name — $detail"; ((warn++)) ;;
  esac
}

echo "=== Iterator TV Dependency Check ==="
echo ""

# Homebrew
if command -v brew &>/dev/null; then
  check "Homebrew" PASS "$(brew --version | head -1)"
elif [[ "$(uname)" == "Darwin" ]] && [ -f /opt/homebrew/bin/brew ]; then
  check "Homebrew" WARN "Installed at /opt/homebrew/bin but not in PATH — run: echo 'eval \"\$(/opt/homebrew/bin/brew shellenv)\"' >> ~/.zshrc && source ~/.zshrc"
else
  check "Homebrew" FAIL "Not installed"
fi

# Git
if command -v git &>/dev/null; then
  check "Git" PASS "$(git --version)"
else
  check "Git" FAIL "Not installed"
fi

# Docker
if command -v docker &>/dev/null; then
  ver=$(docker --version 2>/dev/null || echo "unknown")
  if docker info &>/dev/null 2>&1; then
    check "Docker" PASS "$ver (running)"
  else
    check "Docker" WARN "$ver (installed but not running — open Docker Desktop)"
  fi
else
  check "Docker" FAIL "Not installed"
fi

# Node.js
if command -v node &>/dev/null; then
  node_ver=$(node --version)
  major=$(echo "$node_ver" | sed 's/^v//' | cut -d. -f1)
  if [ "$major" -eq 20 ]; then
    check "Node.js" PASS "$node_ver"
  else
    check "Node.js" WARN "$node_ver (need v20.x — run: nvm install 20.10)"
  fi
else
  check "Node.js" FAIL "Not installed"
fi

# nvm
if command -v nvm &>/dev/null 2>&1 || [ -d "${NVM_DIR:-$HOME/.nvm}" ]; then
  nvm_ver=$(bash -c 'source "${NVM_DIR:-$HOME/.nvm}/nvm.sh" 2>/dev/null && nvm --version' 2>/dev/null || echo "installed")
  check "nvm" PASS "v$nvm_ver"
else
  check "nvm" FAIL "Not installed"
fi

# pnpm
if command -v pnpm &>/dev/null; then
  pnpm_ver=$(pnpm --version)
  if [ "$pnpm_ver" = "10.19.0" ]; then
    check "pnpm" PASS "v$pnpm_ver"
  else
    check "pnpm" WARN "v$pnpm_ver (need 10.19.0 — run: npm install -g pnpm@10.19.0)"
  fi
else
  check "pnpm" FAIL "Not installed"
fi

# ngrok
if command -v ngrok &>/dev/null; then
  check "ngrok" PASS "$(ngrok version 2>/dev/null || echo 'installed')"
else
  check "ngrok" FAIL "Not installed — run: brew install ngrok (needed for video rendering)"
fi

# ngrok config in .env.local
if [ -f "apps/web/.env.local" ]; then
  if grep -q 'NGROK_URL=.*ngrok-free.app' apps/web/.env.local 2>/dev/null; then
    ngrok_domain=$(grep 'NGROK_URL=' apps/web/.env.local | head -1 | cut -d= -f2)
    check "ngrok domain" PASS "$ngrok_domain"
  else
    check "ngrok domain" WARN "No ngrok domain in .env.local — see _docs/getting-started.md for setup"
  fi
fi

# .env.local
if [ -f "apps/web/.env.local" ]; then
  check ".env.local" PASS "Found at apps/web/.env.local"
else
  check ".env.local" FAIL "Missing — get this file from Tyler and place at apps/web/.env.local"
fi

# node_modules
if [ -d "node_modules" ]; then
  check "Dependencies" PASS "node_modules exists (pnpm install has been run)"
else
  check "Dependencies" FAIL "node_modules missing — run: pnpm install"
fi

# Profile B check (macOS port 7000 conflict)
if [[ "$(uname)" == "Darwin" ]]; then
  if grep -q 'port = 28885' apps/web/supabase/config.toml 2>/dev/null; then
    check "Profile B" PASS "Config is set to Profile B (avoids macOS port 7000 conflict)"
  else
    check "Profile B" WARN "Still on default profile — run: pnpm bump:config B --no-skip-worktree"
  fi
fi

echo ""
echo "=== Summary: $pass passed, $fail failed, $warn warnings ==="

if [ "$fail" -gt 0 ]; then
  echo -e "${RED}Some dependencies are missing. See above for install instructions.${NC}"
  exit 1
elif [ "$warn" -gt 0 ]; then
  echo -e "${YELLOW}Some items need attention. See warnings above.${NC}"
  exit 0
else
  echo -e "${GREEN}All good! You're ready to run the app.${NC}"
  exit 0
fi
