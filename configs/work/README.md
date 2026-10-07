# Development Workspace (`~/Work`)

## Directory Layout
- `~/Work/dev`: Active projects and experimental checkouts
- `~/Work/projects`: Canonical checkouts and bare repositories
- `~/Work/worktrees`: Git worktree checkouts for parallel feature/hotfix branches

## Git Worktree Quick Reference
OMP and Git worktree aliases configured:
- `git wt`: shortcut for `git worktree`
- `git wtl`: list active worktrees (`git worktree list`)
- `git wta <path> <branch>`: add worktree (`git worktree add <path> <branch>`)
- `git wtr <path>`: remove worktree (`git worktree remove <path>`)
- `git wtp`: prune dead worktrees (`git worktree prune`)

### Example: Bare Repo + Worktree Workflow
```bash
# 1. Clone a repo as bare in ~/Work/projects
git clone --bare git@github.com:user/repo.git ~/Work/projects/repo.git

# 2. Add main worktree
git -C ~/Work/projects/repo.git worktree add ~/Work/worktrees/repo/main main

# 3. Add feature branch worktree
git -C ~/Work/projects/repo.git worktree add -b feat-xyz ~/Work/worktrees/repo/feat-xyz main

# 4. View active worktrees
git -C ~/Work/projects/repo.git worktree list
```
