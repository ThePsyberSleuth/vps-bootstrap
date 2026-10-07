#!/usr/bin/env bash
# ==============================================================================
# VPS Hardening & Developer Environment Bootstrap
# Interactive & automated setup for fresh Ubuntu/Debian servers.
# ==============================================================================
set -euo pipefail

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m' # No Color

# Script Directory Resolution
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_URL="https://github.com/ThePsyberSleuth/vps-bootstrap.git"

# Check Root
if [ "$EUID" -ne 0 ]; then
  echo -e "${RED}Error: This installer must be run as root (or with sudo).${NC}" >&2
  exit 1
fi

# Self-bootstrap if executed via curl pipe without local configs
if [ ! -d "${SCRIPT_DIR}/configs" ]; then
  echo -e "${CYAN}==> Bootstrapping from repository...${NC}"
  TEMP_DIR="/tmp/vps-bootstrap-$(date +%s)"
  if command -v git &>/dev/null; then
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
  else
    apt-get update -qq && apt-get install -y -qq git
    git clone --depth 1 "$REPO_URL" "$TEMP_DIR"
  fi
  exec bash "${TEMP_DIR}/bootstrap.sh" "$@"
fi

# Parse Flags
NON_INTERACTIVE=false
for arg in "$@"; do
  case "$arg" in
    -y|--yes|--non-interactive)
      NON_INTERACTIVE=true
      ;;
    -h|--help)
      echo "Usage: ./bootstrap.sh [OPTIONS]"
      echo "  -y, --yes, --non-interactive  Run without prompting, using defaults or env vars"
      echo "  -h, --help                    Show this help message"
      exit 0
      ;;
  esac
done

# Defaults / Environment Variables
DEV_USER="${DEV_USER:-dev}"
DEV_PASSWORD="${DEV_PASSWORD:-}"
ROOT_PASSWORD="${ROOT_PASSWORD:-}"
GIT_USER_NAME="${GIT_USER_NAME:-Developer}"
GIT_USER_EMAIL="${GIT_USER_EMAIL:-dev@example.com}"
HARDEN_SSH="${HARDEN_SSH:-true}"
ENABLE_FAIL2BAN="${ENABLE_FAIL2BAN:-true}"
ENABLE_UFW="${ENABLE_UFW:-true}"
INSTALL_DEV_TOOLS="${INSTALL_DEV_TOOLS:-true}"
INSTALL_OMP="${INSTALL_OMP:-true}"
INSTALL_TERN="${INSTALL_TERN:-true}"
CREATE_WORKSPACE="${CREATE_WORKSPACE:-true}"

# ──────────────────────────────────────────────────────────────────────────────
# Interactive Setup Wizard
# ──────────────────────────────────────────────────────────────────────────────
echo -e "${BOLD}${CYAN}"
cat << "BANNER"
  ____   ____  ____  ____    ____             _       _                   
 |  _ \ / ___||  _ \/ ___|  | __ )  ___   ___| |_ ___| |_ _ __ __ _ _ __  
 | | | | |    | |_) \___ \  |  _ \ / _ \ / _ \ __/ __| __| '__/ _` | '_ \ 
 | |_| | |___ |  __/ ___) | | |_) | (_) | (_) | |_\__ \ |_| | | (_| | |_) |
 |____/ \____||_|   |____/  |____/ \___/ \___/ \__|___/\__|_|  \__,_| .__/ 
                                                                    |_|    
BANNER
echo -e "${NC}"
echo -e "${BOLD}Welcome to the VPS Hardening & Dev Environment Provisioner.${NC}"
echo -e "This wizard will configure a secure developer environment.\n"

prompt_yn() {
  local prompt="$1"
  local default="$2"
  if [ "$NON_INTERACTIVE" = true ]; then
    [ "$default" = "y" ] && return 0 || return 1
  fi
  while true; do
    read -rp "$(echo -e "${CYAN}?${NC} ${prompt} [${default^^}/${default}]: ")" answer
    answer="${answer:-$default}"
    case "${answer,,}" in
      y|yes) return 0 ;;
      n|no) return 1 ;;
      *) echo -e "${YELLOW}Please answer y or n.${NC}" ;;
    esac
  done
}

if [ "$NON_INTERACTIVE" = false ]; then
  echo -e "${BOLD}--- [1/4] User & Credentials Configuration ---${NC}"
  read -rp "$(echo -e "${CYAN}?${NC} Primary non-root username [${GREEN}${DEV_USER}${NC}]: ")" input_user
  DEV_USER="${input_user:-$DEV_USER}"

  # User Password
  while true; do
    read -rsp "$(echo -e "${CYAN}?${NC} Enter password for user '${DEV_USER}' (leave empty to generate random): ")" pass1
    echo
    if [ -z "$pass1" ]; then
      DEV_PASSWORD=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 20 || true)
      echo -e "${YELLOW}Generated random password for ${DEV_USER}:${NC} ${BOLD}${DEV_PASSWORD}${NC}"
      break
    fi
    read -rsp "$(echo -e "${CYAN}?${NC} Confirm password: ")" pass2
    echo
    if [ "$pass1" = "$pass2" ]; then
      DEV_PASSWORD="$pass1"
      break
    else
      echo -e "${RED}Passwords do not match. Please try again.${NC}"
    fi
  done

  # Root Password
  while true; do
    read -rsp "$(echo -e "${CYAN}?${NC} Enter password for 'root' (leave empty to generate random): ")" rpass1
    echo
    if [ -z "$rpass1" ]; then
      ROOT_PASSWORD=$(tr -dc 'A-Za-z0-9!@#%^&*' </dev/urandom | head -c 20 || true)
      echo -e "${YELLOW}Generated random password for root:${NC} ${BOLD}${ROOT_PASSWORD}${NC}"
      break
    fi
    read -rsp "$(echo -e "${CYAN}?${NC} Confirm root password: ")" rpass2
    echo
    if [ "$rpass1" = "$rpass2" ]; then
      ROOT_PASSWORD="$rpass1"
      break
    else
      echo -e "${RED}Passwords do not match. Please try again.${NC}"
    fi
  done

  echo -e "\n${BOLD}--- [2/4] Git & Author Information ---${NC}"
  read -rp "$(echo -e "${CYAN}?${NC} Git author name [${GREEN}${GIT_USER_NAME}${NC}]: ")" input_git_name
  GIT_USER_NAME="${input_git_name:-$GIT_USER_NAME}"

  read -rp "$(echo -e "${CYAN}?${NC} Git author email [${GREEN}${GIT_USER_EMAIL}${NC}]: ")" input_git_email
  GIT_USER_EMAIL="${input_git_email:-$GIT_USER_EMAIL}"

  echo -e "\n${BOLD}--- [3/4] Security & Hardening Features ---${NC}"
  prompt_yn "Harden SSH daemon (disable password logins, key-only)" "y" && HARDEN_SSH=true || HARDEN_SSH=false
  prompt_yn "Install & enable Fail2Ban intrusion prevention" "y" && ENABLE_FAIL2BAN=true || ENABLE_FAIL2BAN=false
  prompt_yn "Configure UFW firewall (allow SSH & Tern P2P)" "y" && ENABLE_UFW=true || ENABLE_UFW=false

  echo -e "\n${BOLD}--- [4/4] Developer Toolchain & Environment ---${NC}"
  prompt_yn "Install Mise + runtimes (Node, Bun, pnpm, Go, uv/Python, Rust, CLI tools)" "y" && INSTALL_DEV_TOOLS=true || INSTALL_DEV_TOOLS=false
  prompt_yn "Install & configure OMP (oh-my-pi)" "y" && INSTALL_OMP=true || INSTALL_OMP=false
  prompt_yn "Install & configure Tern multiplexing terminal" "y" && INSTALL_TERN=true || INSTALL_TERN=false
  prompt_yn "Create structured ~/Work dev workspace & worktree layout" "y" && CREATE_WORKSPACE=true || CREATE_WORKSPACE=false

  echo
  prompt_yn "Ready to begin provisioning with these settings?" "y" || {
    echo -e "${YELLOW}Installation aborted.${NC}"
    exit 0
  }
fi

# ──────────────────────────────────────────────────────────────────────────────
# Execution Phase
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${BLUE}==> [1/10] Setting up user '${DEV_USER}' and privileges...${NC}"
if ! id "$DEV_USER" &>/dev/null; then
  useradd -m -s /bin/bash "$DEV_USER"
  echo -e "${GREEN}✓ Created user ${DEV_USER}${NC}"
fi

groupadd -f docker
usermod -aG sudo,docker "$DEV_USER"

# Set Passwords
if [ -n "$DEV_PASSWORD" ]; then
  echo "${DEV_USER}:${DEV_PASSWORD}" | chpasswd
fi
if [ -n "$ROOT_PASSWORD" ]; then
  echo "root:${ROOT_PASSWORD}" | chpasswd
fi

# Passwordless sudo for dev user
mkdir -p /etc/sudoers.d
echo "${DEV_USER} ALL=(ALL) NOPASSWD:ALL" > "/etc/sudoers.d/${DEV_USER}"
chmod 440 "/etc/sudoers.d/${DEV_USER}"
visudo -c -f "/etc/sudoers.d/${DEV_USER}" >/dev/null
echo -e "${GREEN}✓ Configured passwordless sudo for ${DEV_USER}${NC}"

echo -e "\n${BOLD}${BLUE}==> [2/10] Configuring SSH keys...${NC}"
mkdir -p "/home/${DEV_USER}/.ssh" /root/.ssh
if [ -f /root/.ssh/authorized_keys ] && [ ! -s "/home/${DEV_USER}/.ssh/authorized_keys" ]; then
  cp /root/.ssh/authorized_keys "/home/${DEV_USER}/.ssh/authorized_keys"
  echo -e "${GREEN}✓ Imported SSH authorized_keys from root to ${DEV_USER}${NC}"
fi

chown -R "${DEV_USER}:${DEV_USER}" "/home/${DEV_USER}/.ssh"
chmod 700 "/home/${DEV_USER}/.ssh" /root/.ssh
[ -f "/home/${DEV_USER}/.ssh/authorized_keys" ] && chmod 600 "/home/${DEV_USER}/.ssh/authorized_keys"
[ -f /root/.ssh/authorized_keys ] && chmod 600 /root/.ssh/authorized_keys

if [ "$HARDEN_SSH" = true ]; then
  echo -e "\n${BOLD}${BLUE}==> [3/10] Applying OpenSSH daemon hardening...${NC}"
  mkdir -p /etc/ssh/sshd_config.d
  cp "${SCRIPT_DIR}/configs/sshd/99-hardened.conf" /etc/ssh/sshd_config.d/99-hardened.conf
  chmod 644 /etc/ssh/sshd_config.d/99-hardened.conf
  sshd -t
  systemctl reload ssh 2>/dev/null || systemctl reload sshd 2>/dev/null || true
  echo -e "${GREEN}✓ Hardened SSH daemon (password logins disabled, publickey enforced)${NC}"
fi

echo -e "\n${BOLD}${BLUE}==> [4/10] Applying kernel security sysctl parameters...${NC}"
mkdir -p /etc/sysctl.d
cp "${SCRIPT_DIR}/configs/sysctl/99-security.conf" /etc/sysctl.d/99-security.conf
sysctl -p /etc/sysctl.d/99-security.conf >/dev/null
echo -e "${GREEN}✓ Applied kernel network & system security parameters${NC}"

if [ "$ENABLE_UFW" = true ] && command -v ufw &>/dev/null; then
  echo -e "\n${BOLD}${BLUE}==> [5/10] Configuring UFW firewall rules...${NC}"
  ufw allow 22/tcp comment "SSH access" >/dev/null
  ufw allow 8376/udp comment "tern direct p2p" >/dev/null
  ufw status | grep -q "22/tcp.*LIMIT" && ufw allow 22/tcp >/dev/null
  echo -e "${GREEN}✓ Configured firewall rules (22/tcp SSH, 8376/udp Tern)${NC}"
fi

echo -e "\n${BOLD}${BLUE}==> [6/10] Installing essential system packages...${NC}"
export DEBIAN_FRONTEND=noninteractive
apt-get update -qq
apt-get install -y -qq \
  build-essential pkg-config libssl-dev git curl wget jq ripgrep fd-find \
  unzip tmux ca-certificates

[ -x "$(which fdfind 2>/dev/null)" ] && ln -sf "$(which fdfind)" /usr/local/bin/fd

# Install GitHub CLI (gh) if missing
if ! command -v gh &>/dev/null; then
  mkdir -p -m 755 /etc/apt/keyrings
  wget -qO- https://cli.github.com/packages/githubcli-archive-keyring.gpg | tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" | tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  apt-get update -qq && apt-get install -y -qq gh
fi
echo -e "${GREEN}✓ System build tools, CLI packages, and GitHub CLI installed${NC}"

if [ "$ENABLE_FAIL2BAN" = true ]; then
  echo -e "\n${BOLD}${BLUE}==> [7/10] Installing & configuring Fail2Ban...${NC}"
  apt-get install -y -qq fail2ban
  cp "${SCRIPT_DIR}/configs/fail2ban/jail.local" /etc/fail2ban/jail.local
  systemctl restart fail2ban 2>/dev/null || true
  systemctl enable fail2ban 2>/dev/null || true
  echo -e "${GREEN}✓ Fail2Ban active and monitoring SSH service${NC}"
fi

if [ "$INSTALL_DEV_TOOLS" = true ]; then
  echo -e "\n${BOLD}${BLUE}==> [8/10] Installing Mise version manager & developer toolchain...${NC}"
  if [ ! -x /usr/local/bin/mise ]; then
    curl -fSL https://mise.jdx.dev/mise-latest-linux-x64 -o /usr/local/bin/mise
    chmod 755 /usr/local/bin/mise
  fi
  /usr/local/bin/mise completions bash > /etc/bash_completion.d/mise 2>/dev/null || true

  sudo -u "$DEV_USER" mkdir -p "/home/${DEV_USER}/.config/mise"
  sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/mise/config.toml" "/home/${DEV_USER}/.config/mise/config.toml"
  if [ -f "${SCRIPT_DIR}/configs/mise/github_tokens.toml" ]; then
    sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/mise/github_tokens.toml" "/home/${DEV_USER}/.config/mise/github_tokens.toml"
    chmod 600 "/home/${DEV_USER}/.config/mise/github_tokens.toml"
  fi

  echo -e "Installing runtimes (Node, Bun, pnpm, Go, uv, Rust) and CLI tools..."
  sudo -u "$DEV_USER" -H bash -c '
    export PATH="/usr/local/bin:$PATH"
    eval "$(/usr/local/bin/mise activate bash)"
    mise install --yes
    mise reshim
  '
  echo -e "${GREEN}✓ Mise development runtimes and tools installed${NC}"
fi

echo -e "\n${BOLD}${BLUE}==> [9/10] Deploying shell dotfiles & Git configuration...${NC}"
sudo -u "$DEV_USER" mkdir -p "/home/${DEV_USER}/.config"
sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/dotfiles/starship.toml" "/home/${DEV_USER}/.config/starship.toml"
sudo -u "$DEV_USER" mkdir -p "/home/${DEV_USER}/.config/tmux"
sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/dotfiles/tmux.conf" "/home/${DEV_USER}/.config/tmux/tmux.conf"
sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/dotfiles/bash_aliases" "/home/${DEV_USER}/.bash_aliases"
sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/dotfiles/bashrc" "/home/${DEV_USER}/.bashrc"

# Git Config
sudo -u "$DEV_USER" git config --global user.name "$GIT_USER_NAME"
sudo -u "$DEV_USER" git config --global user.email "$GIT_USER_EMAIL"
sudo -u "$DEV_USER" git config --global init.defaultBranch main
sudo -u "$DEV_USER" git config --global pull.rebase false
sudo -u "$DEV_USER" git config --global core.autocrlf input
sudo -u "$DEV_USER" git config --global worktree.guessRemote true
sudo -u "$DEV_USER" git config --global diff.algorithm histogram
sudo -u "$DEV_USER" git config --global diff.colorMoved plain
sudo -u "$DEV_USER" git config --global diff.mnemonicPrefix true
sudo -u "$DEV_USER" git config --global commit.verbose true
sudo -u "$DEV_USER" git config --global column.ui auto
sudo -u "$DEV_USER" git config --global branch.sort -committerdate
sudo -u "$DEV_USER" git config --global tag.sort -version:refname
sudo -u "$DEV_USER" git config --global rerere.enabled true
sudo -u "$DEV_USER" git config --global rerere.autoUpdate true
sudo -u "$DEV_USER" git config --global push.autoSetupRemote true
sudo -u "$DEV_USER" git config --global core.pager delta
sudo -u "$DEV_USER" git config --global interactive.diffFilter "delta --color-only"
sudo -u "$DEV_USER" git config --global delta.navigate true
sudo -u "$DEV_USER" git config --global delta.line-numbers true
sudo -u "$DEV_USER" git config --global alias.wt "worktree"
sudo -u "$DEV_USER" git config --global alias.wtl "worktree list"
sudo -u "$DEV_USER" git config --global alias.wta "worktree add"
sudo -u "$DEV_USER" git config --global alias.wtr "worktree remove"
sudo -u "$DEV_USER" git config --global alias.wtp "worktree prune"
sudo -u "$DEV_USER" git config --global alias.st "status -sb"
sudo -u "$DEV_USER" git config --global alias.br "branch -a"
sudo -u "$DEV_USER" git config --global alias.lg "log --graph --pretty=format:'%Cred%h%Creset -%C(yellow)%d%Creset %s %Cgreen(%cr) %C(bold blue)<%an>%Creset' --abbrev-commit"

# Generate SSH Keypair for Git
if [ ! -f "/home/${DEV_USER}/.ssh/id_ed25519" ]; then
  sudo -u "$DEV_USER" ssh-keygen -t ed25519 -C "$GIT_USER_EMAIL" -f "/home/${DEV_USER}/.ssh/id_ed25519" -N ""
  sudo -u "$DEV_USER" ssh-keyscan -t ed25519 github.com >> "/home/${DEV_USER}/.ssh/known_hosts" 2>/dev/null || true
  chmod 644 "/home/${DEV_USER}/.ssh/known_hosts" 2>/dev/null || true
  echo -e "${GREEN}✓ Generated Git SSH key (~/.ssh/id_ed25519)${NC}"
fi

if [ "$CREATE_WORKSPACE" = true ]; then
  sudo -u "$DEV_USER" mkdir -p "/home/${DEV_USER}/Work"/{dev,projects,worktrees}
  sudo -u "$DEV_USER" cp "${SCRIPT_DIR}/configs/work/README.md" "/home/${DEV_USER}/Work/README.md"
  echo -e "${GREEN}✓ Initialized ~/Work directory structure & worktree layout${NC}"
fi

echo -e "\n${BOLD}${BLUE}==> [10/10] Setting up agent environments & remoting...${NC}"
if [ "$INSTALL_OMP" = true ]; then
  mkdir -p "/home/${DEV_USER}/.omp/agent" /root/.omp/agent
  for TARGET in "/home/${DEV_USER}" "/root"; do
    cp "${SCRIPT_DIR}/configs/omp/config.yml" "${TARGET}/.omp/agent/config.yml"
    cp "${SCRIPT_DIR}/configs/omp/models.yml" "${TARGET}/.omp/agent/models.yml"
    if [ -f "${SCRIPT_DIR}/configs/omp/.env" ]; then
      cp "${SCRIPT_DIR}/configs/omp/.env" "${TARGET}/.omp/agent/.env"
    elif [ -f "${SCRIPT_DIR}/configs/omp/.env.template" ]; then
      cp "${SCRIPT_DIR}/configs/omp/.env.template" "${TARGET}/.omp/agent/.env"
    fi
    chmod 700 "${TARGET}/.omp" "${TARGET}/.omp/agent"
    chmod 600 "${TARGET}/.omp/agent/"*
  done
  chown -R "${DEV_USER}:${DEV_USER}" "/home/${DEV_USER}/.omp"
  echo -e "${GREEN}✓ OMP agent directories initialized${NC}"
fi

# ──────────────────────────────────────────────────────────────────────────────
# Completion Summary
# ──────────────────────────────────────────────────────────────────────────────
echo -e "\n${BOLD}${GREEN}=================================================================${NC}"
echo -e "${BOLD}${GREEN}  Provisioning Complete! Server is hardened & ready for development.${NC}"
echo -e "${BOLD}${GREEN}=================================================================${NC}"
echo -e "\n${BOLD}Primary User:${NC}     ${GREEN}${DEV_USER}${NC}"
if [ -n "$DEV_PASSWORD" ]; then
  echo -e "${BOLD}User Password:${NC}    ${DEV_PASSWORD}"
fi
if [ -n "$ROOT_PASSWORD" ]; then
  echo -e "${BOLD}Root Password:${NC}    ${ROOT_PASSWORD}"
fi
echo -e "${BOLD}SSH Access:${NC}       ssh ${DEV_USER}@<vps-ip>"
echo -e "${BOLD}Git Public Key:${NC}   cat /home/${DEV_USER}/.ssh/id_ed25519.pub"
echo -e "\n${YELLOW}Note:${NC} Re-login or run 'source ~/.bashrc' to activate the shell environment."
