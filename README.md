# VPS Hardening & Developer Environment Bootstrap

Automated, interactive provisioning suite to bootstrap a fresh Linux VPS (Ubuntu/Debian) into a hardened, production-grade developer workstation.

Includes OpenSSH hardening, Fail2Ban, UFW firewall, kernel security sysctl parameters, Mise version manager (Node, Bun, pnpm, Go, uv/Python, Rust), modern CLI utilities, Git worktree workflow, and OMP agent environment.

---

## Quick Start on a New VPS

### Method 1: Interactive Run directly on the New VPS (Recommended)

SSH into your fresh VPS as `root` and run:

```bash
git clone https://github.com/ThePsyberSleuth/vps-bootstrap.git ~/vps-bootstrap
cd ~/vps-bootstrap
./bootstrap.sh
```

An interactive setup wizard will guide you through:
- Choosing a primary non-root username (default: `dev`)
- Setting secure passwords for the user and `root` (or generating random passwords)
- Configuring Git author name and email
- Selecting security features (SSH key-only auth, Fail2Ban, UFW firewall)
- Choosing runtime and toolchain installations

> **Non-Interactive Mode:**  
> Run `./bootstrap.sh -y` to run completely unattended using defaults or environment variables (`DEV_USER`, `DEV_PASSWORD`, `ROOT_PASSWORD`, `GIT_USER_NAME`, `GIT_USER_EMAIL`).

---

### Method 2: Remote Deployment from Local Machine

From your local machine, run:

```bash
cd vps-bootstrap
./deploy.sh root@<YOUR_VPS_IP>
```

This will automatically bundle any local configuration overlays, upload the installer to the remote host, launch the interactive setup wizard over SSH, and pair Tern remoting upon completion.

---

## What Gets Configured

### 1. User & Access Security
- **Primary Dev User**: Standard user account with `sudo` and `docker` groups.
- **Passwordless Sudo**: `/etc/sudoers.d/<user>` configured with `NOPASSWD:ALL` for frictionless development.
- **SSH Key Authentication**: Public key automatically imported from `/root/.ssh/authorized_keys` to the dev user.

### 2. Server & SSH Hardening
- **OpenSSH Daemon (`/etc/ssh/sshd_config.d/99-hardened.conf`)**:
  - `PasswordAuthentication no` (strictly enforces SSH public key authentication)
  - `KbdInteractiveAuthentication no`
  - `AuthenticationMethods publickey`
  - `PermitRootLogin prohibit-password`
  - `MaxAuthTries 3`
  - `X11Forwarding no`
  - `ClientAliveInterval 300` / `ClientAliveCountMax 2`
- **Fail2Ban (`/etc/fail2ban/jail.local`)**:
  - SSH jail enabled using systemd journal backend.
  - Ban time: 1 hour (`bantime = 1h`), find time: 10 minutes, max retries: 4.
  - Automatic bans integrated with `ufw`.
- **UFW Firewall**:
  - Port `22/tcp` allowed (standard allow, preventing rate-limit lockouts).
  - Port `8376/udp` allowed for Tern direct peer-to-peer communication.
  - Existing Docker container port forwardings preserved.
- **Kernel Hardening (`/etc/sysctl.d/99-security.conf`)**:
  - TCP SYN cookies enabled (`net.ipv4.tcp_syncookies = 1`).
  - IP source routing and ICMP redirect acceptance disabled.
  - Martian packet logging enabled.
  - Kernel pointers and dmesg access restricted (`kernel.kptr_restrict = 2`, `kernel.dmesg_restrict = 1`).
  - Container IP forwarding preserved (`net.ipv4.ip_forward = 1`).

### 3. Toolchain & Runtimes (via `mise`)
- **Mise Version Manager**: Installed globally at `/usr/local/bin/mise`.
- **Runtimes Installed**:
  - Node.js LTS
  - Bun (latest)
  - pnpm (latest)
  - Go (latest)
  - uv (fast Python package manager)
  - Rust toolchain (`rustc`, `cargo`, `rustup`)
- **CLI Utilities Installed**:
  - `starship`: Fast, customizable shell prompt
  - `zoxide`: Smart directory jumper (`cd` / `z`)
  - `fzf`: Command-line fuzzy finder
  - `eza`: Modern `ls` with tree, icons, and git integration
  - `bat`: Syntax-highlighted file viewer
  - `lazygit`: Terminal UI for git
  - `neovim`: Extensible modal text editor (LazyVim compatible)
  - `delta`: Syntax-highlighting pager for git diffs
  - `btop`: Interactive resource monitor
  - `oh-my-pi` (`omp`): AI coding agent framework (managed directly by mise)

### 4. Dotfiles & Shell Environment
- **`~/.config/starship.toml`**: Custom prompt layout (`…/Work/dev ❯ `).
- **`~/.config/tmux/tmux.conf`**: `C-Space` prefix, vi copy mode, split pane controls, and top status bar.
- **`~/.bash_aliases`**:
  - `ls`, `ll`, `la`, `lt` $\rightarrow$ `eza`
  - `cat` $\rightarrow$ `bat --paging=never`
  - `ff` $\rightarrow$ `fzf --preview 'bat ...'`
  - `cd` $\rightarrow$ `zd` (Zoxide smart navigation)
  - `cdw` $\rightarrow$ `~/Work`
  - `cdd` $\rightarrow$ `~/Work/dev`
  - `cdp` $\rightarrow$ `~/Work/projects`
  - `cdwt` $\rightarrow$ `~/Work/worktrees`
  - `t` $\rightarrow$ `tmux attach || tmux new -s Work`

### 5. Git & Worktree Workflow
- Configured with `delta` pager, histogram diff algorithm, rerere, and committer-date branch sorting.
- Worktree aliases: `git wt`, `git wtl`, `git wta`, `git wtr`, `git wtp`.
- Auto-generated `~/.ssh/id_ed25519` keypair with GitHub pre-populated in `known_hosts`.
- Workspace directory hierarchy under `~/Work/`:
  - `~/Work/dev`: Scratchpad and feature repos.
  - `~/Work/projects`: Canonical checkouts.
  - `~/Work/worktrees`: Git worktree checkouts for parallel feature development.

### 6. OMP Agent Environment
- Configured at `~/.omp/agent/` for the dev user and root.
- Deploys `config.yml`, `models.yml`, and template `.env`.

---

## Repository Structure

```text
vps-bootstrap/
├── deploy.sh                        # Remote deployment runner
├── bootstrap.sh                     # Interactive server provisioning script
├── README.md                        # Documentation and instructions
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
