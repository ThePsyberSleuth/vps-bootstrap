# VPS Hardening & Developer Environment Bootstrap

[![OS: Ubuntu 24.04+ / Debian](https://img.shields.io/badge/OS-Ubuntu%2024.04+%20%7C%20Debian-E95420?logo=ubuntu&logoColor=white)](#)
[![Security: Hardened SSH + Fail2Ban](https://img.shields.io/badge/Security-Hardened%20SSH%20%2B%20Fail2Ban-2ea44f?logo=shield&logoColor=white)](#)
[![Toolchain: Mise](https://img.shields.io/badge/Toolchain-Mise-000000?logo=rust&logoColor=white)](#)
[![Runtimes: Rust + Node + Bun + Go + uv](https://img.shields.io/badge/Runtimes-Rust%20%7C%20Node%20%7C%20Bun%20%7C%20Go%20%7C%20uv-blue)](#)
[![Terminal: Tern + Tmux + Starship](https://img.shields.io/badge/Terminal-Tern%20%7C%20Tmux%20%7C%20Starship-8A2BE2)](#)
[![AI Agent: OMP](https://img.shields.io/badge/AI%20Agent-oh--my--pi%20(OMP)-orange)](#)

An automated, interactive provisioning suite that transforms any fresh Linux VPS into a hardened, production-grade developer workstation. 

Pairs enterprise-level server security (SSH key-only auth, Fail2Ban, UFW, kernel sysctl tuning) with a modern developer environment featuring **Mise**, **Rust**, **Tern** (persistent P2P multiplexer), **OMP** (autonomous coding agent), **Starship**, **LazyVim**, and **Git Worktree** workflows.

---

## Table of Contents
- [Quick Start](#quick-start)
  - [Interactive Mode (Direct on Target VPS)](#1-interactive-mode-direct-on-target-vps)
  - [One-Command Remote Deploy (From Local Machine)](#2-one-command-remote-deploy-from-local-machine)
- [Architecture & Security Hardening](#architecture--security-hardening)
- [Tern Multiplexer Setup & Workflows](#tern-multiplexer-setup--workflows)
- [OMP (oh-my-pi) Coding Agent Setup & Workflows](#omp-oh-my-pi-coding-agent-setup--workflows)
- [Git Worktree & Parallel Development](#git-worktree--parallel-development)
- [CLI Productivity Suite & Aliases](#cli-productivity-suite--aliases)
- [Repository Structure](#repository-structure)

---

## Quick Start

### 1. Interactive Mode (Direct on Target VPS)
Log into your fresh VPS as `root` and run:

```bash
git clone https://github.com/ThePsyberSleuth/vps-bootstrap.git ~/vps-bootstrap
cd ~/vps-bootstrap
./bootstrap.sh
```

The interactive setup wizard will guide you through:
- Setting a custom non-root username (default: `dev`)
- Setting secure passwords for the user and `root` (or generating random ones)
- Importing active SSH keys from `/root/.ssh/authorized_keys`
- Configuring Git author identity
- Toggling hardening (SSH key-only auth, Fail2Ban, UFW firewall)
- Installing developer runtimes and CLI utilities

> **Unattended / CI Mode:**  
> Pass `-y` or `--non-interactive` to execute immediately using defaults or environment variables:
> ```bash
> DEV_USER="developer" DEV_PASSWORD="SecretPassword" ./bootstrap.sh -y
> ```

---

### 2. One-Command Remote Deploy (From Local Machine)
From your local terminal:

```bash
git clone https://github.com/ThePsyberSleuth/vps-bootstrap.git
cd vps-bootstrap
./deploy.sh root@<YOUR_VPS_IP>
```

This bundles local configuration overlays, uploads the payload, opens an interactive SSH terminal for the wizard, and automatically pairs **Tern remoting** upon completion.

---

## Architecture & Security Hardening

```
┌────────────────────────────────────────────────────────┐
│                      Internet                          │
└───────────────┬────────────────────────┬───────────────┘
                │ Port 22/tcp (SSH)      │ Port 8376/udp (Tern P2P)
                ▼                        ▼
┌────────────────────────────────────────────────────────┐
│                      UFW Firewall                      │
│        (Rate-limit lockouts removed; Docker preserved) │
├────────────────────────────────────────────────────────┤
│                 Fail2Ban Intrusion Jail                │
│    (Systemd journal backend; automatic 1h UFW bans)    │
├────────────────────────────────────────────────────────┤
│               OpenSSH Hardening (99-hardened)          │
│    • PasswordAuthentication: no                        │
│    • KbdInteractiveAuthentication: no                  │
│    • AuthenticationMethods: publickey                  │
│    • PermitRootLogin: prohibit-password                │
│    • MaxAuthTries: 3 | ClientAliveInterval: 300        │
├────────────────────────────────────────────────────────┤
│                Linux Kernel Hardening                  │
│    • TCP SYN Cookies: enabled                          │
│    • ICMP Redirects / Source Routing: disabled         │
│    • Martian Packet Logging: enabled                   │
│    • Kernel Pointers & dmesg: restricted               │
│    • Container IP Forwarding: preserved                │
└────────────────────────────────────────────────────────┘
```

---

## Tern Multiplexer Setup & Workflows

[Tern](https://github.com/stencil-hq/tern) is a next-generation terminal multiplexer designed for remote development. It provides persistent daemon-backed sessions, seamless window splitting, and secure peer-to-peer connectivity over [Iroh](https://iroh.computer) and direct UDP.

### Why Tern?
- **Persistent Sessions**: Background daemon runs under user systemd (`tern-remote.service`) with `Linger=yes`. Long-running compiles, tests, and servers survive network drops and reboots.
- **Direct P2P Low-Latency**: While traditional SSH multiplexers can feel sluggish across continents, Tern punches direct UDP NAT traversal (`8376/udp`) for instantaneous keystrokes.
- **Cryptographic Trust**: Authenticates using Ed25519 host and client keys pinned in `~/.config/tern/known_hosts`.

### Management & Health Commands
```bash
# Verify connection health, P2P latency, and pinned keys
tern remote doctor user@<vps-ip>

# List all paired remote hosts
tern remote hosts

# Update remote Tern binary
tern remote update user@<vps-ip>
```

### Daily Development Flow in Tern
```bash
# 1. Connect directly from your local terminal
tern ssh user@<vps-ip>

# 2. Split current workspace vertically
tern split right

# 3. Open files in side-by-side tabs
tern open src/main.rs

# 4. Detach safely — processes continue running in the background
# Reconnect anytime: your buffers, scrollback, and processes remain intact.
```

---

## OMP (oh-my-pi) Coding Agent Setup & Workflows

[OMP](https://github.com/can1357/oh-my-pi) (`oh-my-pi`) is an autonomous AI coding agent designed for complex software engineering tasks. It features AST structural search and edit, Language Server Protocol (LSP) diagnostics, subagent delegation, and hashline precision edits.

### Managed via Mise
OMP is managed as a first-class tool under `~/.config/mise/config.toml`:
```toml
[tools]
"github:can1357/oh-my-pi" = { version = "latest", minimum_release_age = "0s" }
```
- **Update anytime**: Run `mise up` or `mup` to automatically fetch and apply the latest OMP release.
- **Verification**: `omp --version`

### Agent Configuration (`~/.omp/agent/`)
- **`config.yml`**: Configures hashline edit mode, compaction strategies, AST grep integration, and security controls.
- **`models.yml`**: Routes model requests across providers (OmniRoute, Kourier, OpenAI, Anthropic, Gemini, local models).
- **`.env`**: Stores encrypted/isolated API keys (`OPENAI_API_KEY`, `OMNIROUTE_API_KEY`, `ANTHROPIC_API_KEY`).

### Core OMP Workflows

#### 1. Interactive Fullscreen Agent
Launch the full interactive TUI inside a Tern or Tmux pane:
```bash
omp
```
Use `Ctrl+P` to switch active model roles (Fast/Smol $\leftrightarrow$ Reasoning/Slow $\leftrightarrow$ Plan).

#### 2. Goal-Oriented Autonomous Mode
Direct OMP to solve a multi-step objective without manual micromanagement:
```bash
omp --goal "Audit error handling in src/api/ and write unit tests for edge cases"
```

#### 3. Architecture & Planning Mode
Generate a structured design and implementation plan before touching code:
```bash
omp --plan "Architect database schema and migration strategy for multi-tenant accounts"
```

#### 4. Headless & Piping Execution
Process tasks non-interactively in scripts or CI:
```bash
omp -p "Summarize recent commits and generate a changelog" > CHANGELOG.md
```

---

## Git Worktree & Parallel Development

The VPS is configured with a structured `~/Work` layout optimized for parallel development using Git worktrees. This allows running multiple feature branches, builds, and AI subagents concurrently without git stashing or branch switching overhead.

### Workspace Directory Layout
```text
~/Work/
├── dev/             # Scratchpad, experiments, and quick checkouts
├── projects/        # Canonical checkouts and bare repositories
└── worktrees/       # Linked branch checkouts for parallel feature dev
```

### Bare Repository + Worktree Recipe
```bash
# 1. Clone a repository as bare
git clone --bare git@github.com:org/app.git ~/Work/projects/app.git

# 2. Check out the main branch into its own worktree
git -C ~/Work/projects/app.git worktree add ~/Work/worktrees/app/main main

# 3. Create a feature branch worktree for parallel work
git -C ~/Work/projects/app.git worktree add -b feat-auth ~/Work/worktrees/app/feat-auth main

# 4. Run an OMP agent in the feature branch while you code in main
cd ~/Work/worktrees/app/feat-auth
omp --goal "Implement JWT token validation"
```

### Git Worktree Aliases
- `git wt` $\rightarrow$ `git worktree`
- `git wtl` $\rightarrow$ `git worktree list`
- `git wta <path> <branch>` $\rightarrow$ `git worktree add`
- `git wtr <path>` $\rightarrow$ `git worktree remove`
- `git wtp` $\rightarrow$ `git worktree prune`
- `git st` $\rightarrow$ `git status -sb`
- `git lg` $\rightarrow$ Formatted commit graph

---

## CLI Productivity Suite & Aliases

Pre-configured in `~/.bash_aliases` and managed via `mise`:

| Command / Alias | Tool | What It Does |
| :--- | :--- | :--- |
| `ls`, `ll`, `la`, `lt` | **eza** | Modern directory listings with icons, tree hierarchy, and git status |
| `cat <file>` | **bat** | Syntax-highlighted viewer with automatic line numbers |
| `ff` | **fzf + bat** | Interactive fuzzy file finder with live syntax preview |
| `eff` | **$EDITOR + fzf** | Search and immediately edit the selected file |
| `cd <dir>` | **zoxide (zd)** | Smart directory jumping based on frequency and recency |
| `lg` | **lazygit** | Full-featured terminal UI for git staging, commits, and rebasing |
| `top` | **btop** | Real-time interactive CPU, memory, disk, and process monitor |
| `t` | **tmux** | Attach to existing `Work` session or launch a fresh workspace |
| `cdw`, `cdd`, `cdp` | **bash** | Instant navigation to `~/Work`, `~/Work/dev`, `~/Work/projects` |
| `mup` | **mise** | Upgrade all developer runtimes and CLI tools (`mise up`) |

---

## Repository Structure

```text
vps-bootstrap/
├── deploy.sh                        # Remote deployment runner
├── bootstrap.sh                     # Interactive server provisioning script
├── README.md                        # Documentation and architecture guide
└── configs/
    ├── sshd/
    │   └── 99-hardened.conf         # OpenSSH hardening config
    ├── fail2ban/
    │   └── jail.local               # Fail2Ban SSH jail config
    ├── sysctl/
    │   └── 99-security.conf         # Kernel security sysctl parameters
    ├── mise/
    │   ├── config.toml              # Mise toolchain manifest
    │   └── github_tokens.toml.template
    ├── omp/
    │   ├── config.yml               # OMP agent configuration
    │   ├── models.yml               # Provider & model routing
    │   └── .env.template            # API credentials template
    ├── dotfiles/
    │   ├── starship.toml            # Starship prompt configuration
    │   ├── tmux.conf                # Tmux multiplexer configuration
    │   ├── bashrc                   # Bash startup configuration
    │   └── bash_aliases             # CLI aliases and functions
    └── work/
        └── README.md                # Git worktree cheat sheet
```

---

## License

MIT License. Free to use, adapt, and distribute for personal and commercial infrastructure.
