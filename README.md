# Claude Code DevContainer - Dockerized AI Coding Assistant Environment

[![Docker](https://img.shields.io/badge/Docker-Required-blue?logo=docker)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange?logo=ubuntu)](https://ubuntu.com/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A ready-to-use Docker container with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) pre-installed on Ubuntu 24.04. Run Anthropic's AI coding assistant in an isolated, reproducible environment on Linux, macOS, or Windows.

## The Problem

Claude Code is designed for Linux and macOS. On Windows, many tools and shell scripts that Claude Code relies on **don't work correctly** — bash commands fail, file permissions behave differently, and Unix-specific utilities are missing. On any OS, running `--dangerously-skip-permissions` is risky since Claude Code gets unrestricted access to your entire host system.

This project solves both problems: Claude Code runs inside a Linux container where all tools and scripts work correctly, and `--dangerously-skip-permissions` is safely sandboxed — the container isolates it from your host machine.

## Why Use This?

- **Fixes Claude Code on Windows** — eliminates shell compatibility issues, broken scripts, and missing Unix tools
- **Safe `--dangerously-skip-permissions`** — run fully autonomous Claude Code sessions sandboxed inside the container, without risking your host system
- **Zero setup** — build and run with a single command, no manual configuration needed
- **Isolated environment** — keep your host system clean; all dependencies live inside the container
- **Cross-platform** — works on Linux, macOS, and Windows with provided shell and batch scripts
- **Mount your projects** — work on existing local codebases without copying files into the container
- **Persistent config** — your `~/.claude` settings are mounted automatically and survive container restarts
- **Per-project tool versions** — one generic image; Node, Java, Python, etc. are installed by [mise](https://mise.jdx.dev/) from the project's `mise.toml` and cached across containers
- **`claude` wrapper** — `claude` inside the container is always invoked with `--dangerously-skip-permissions`, and on first run auto-initializes `~/.claude.json` (skips onboarding and trust prompts) so sessions start immediately
- **OAuth token passthrough** — host `CLAUDE_CODE_OAUTH_TOKEN` is mounted as a Docker secret (`/run/secrets/claude_token`), avoiding env-var exposure

## What's Inside

| Component | Details |
|-----------|---------|
| **OS** | Ubuntu 24.04 LTS |
| **Claude Code** | Native binary (installed via official installer) |
| **User** | Non-root `dev` with passwordless sudo |
| **Tools** | git, gh, ssh, curl, wget, jq, vim, python3, htop, tree, unzip, tar, less, dnsutils |
| **Tool versions** | [mise](https://mise.jdx.dev/) installs project-specific Node/Java/Python/... on container start |
| **Port** | 3000 exposed, mapped to the first free host port in 3000–3100 (or `--port`) |

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- A Claude account; recommended: set `CLAUDE_CODE_OAUTH_TOKEN` on the host (generate it with `claude setup-token`), otherwise log in inside the container

### Build

```bash
# Linux / macOS
./docker-build.sh

# Windows
docker-build.bat
```

The build always runs with `--no-cache`, so every rebuild installs the latest Claude Code. Use `--recreate` on the next run to apply the new image to an existing container.

### Run

```bash
# Linux / macOS
./docker-run.sh [--workspace <path>] [--name <container-name>] [--port <host-port>] [--ssh] [--recreate]

# Windows
docker-run.bat [--workspace <path>] [--name <container-name>] [--port <host-port>] [--recreate]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--workspace` | Local directory to mount to `/home/dev/<basename>` (basename sanitized to `[a-zA-Z0-9._-]`) | none |
| `--name` | Custom Docker container name | `claude-code-development_<basename>` if `--workspace` given, otherwise `claude-code-development` |
| `--ssh` | Enable SSH agent forwarding (Linux/macOS only) | disabled |
| `--port` | Host port mapped to container port 3000; fails if busy (applied on container creation) | first free port in 3000–3100 |
| `--recreate` | Remove the existing container and create a new one from the current image (data outside mounted volumes is lost) | disabled |

Each project gets its own working directory inside the container and its own container by default, so you can run multiple projects in parallel without collisions.

Re-running the script for an existing container: a stopped container is started (`docker start -ai`); a running one gets an additional shell (`docker exec -it ... bash`), so you can open several terminals into the same container.

#### Examples

```bash
# Empty workspace, default container name
./docker-run.sh

# Mount a local directory
./docker-run.sh --workspace /path/to/your/workspace

# Custom container name only
./docker-run.sh --name my-claude

# Both options, any order
./docker-run.sh --name my-claude --workspace /path/to/your/workspace

# Enable SSH agent forwarding for git operations
./docker-run.sh --ssh --workspace /path/to/your/workspace

# Use a specific host port (error if it is busy)
./docker-run.sh --port 3005 --workspace /path/to/your/workspace

# Recreate the container after rebuilding the image
./docker-run.sh --recreate --workspace /path/to/your/workspace
```

## Volume Mounts

| Host | Container | Description |
|------|-----------|-------------|
| `~/.claude` (Linux/macOS) or `%USERPROFILE%\.claude` (Windows) | `/home/dev/.claude` | Claude Code configuration (always mounted) |
| `~/.gitconfig` | `/home/dev/.gitconfig` (read-only) | Git identity, only mounted if the file exists on the host |
| `~/.config/gh-devcontainer` | `/home/dev/.config/gh` | GitHub CLI auth (`gh auth login`), separate from the host `gh`; created automatically |
| `--workspace <path>` | `/home/dev/<basename>` | Your project directory; container `cwd` is set here |
| Docker volume `claude-devcontainer-mise` | `/home/dev/.local/share/mise` | Tools installed by mise, shared by all containers; survives `--recreate` |
| `~/.config/claude-devcontainer/<container>.token` (from host `CLAUDE_CODE_OAUTH_TOKEN`) | `/run/secrets/claude_token` (read-only) | OAuth token, only mounted if the env var is set when the container is created |

Everything outside these mounts lives only inside the container and is lost on `--recreate`.

## Project Tools (mise)

On every container start, `devcontainer-init` runs `mise install` in the workspace if it finds a version file. Without one, the container starts with the base image only.

```
container start ──► version file in workspace?
                       ├─ yes ──► mise install ──► volume claude-devcontainer-mise (cache)
                       └─ no  ──► skip
```

| File | Example |
|------|---------|
| `mise.toml` | `[tools]`<br>`node = "26"`<br>`java = "temurin-21"` |
| `.tool-versions` | `node 26`<br>`java temurin-21` |
| `.nvmrc` / `.node-version` | `26` |
| `.java-version` | `21` |
| `.python-version` | `3.13` |

Tools are available through mise shims, so `node`, `npm`, `java` work in any shell, including Claude Code's Bash tool.

### Setting up a project

The image contains only mise itself, not the tool versions. Each project must declare its versions, otherwise nothing is installed.

Recommended: add `mise.toml` to the project root and commit it:

```toml
[tools]
node  = "26"
java  = "temurin-21"
maven = "3.9"
```

Or create it from inside the container (writes `mise.toml` and installs the tools):

```bash
mise use node@26 java@temurin-21
```

| Case | What to use |
|------|-------------|
| Several languages (e.g. monorepo with npm + Java) | `mise.toml` in the repo root |
| Different version in a subdirectory | additional `mise.toml` in that subdirectory (the nearest file wins) |
| CI or other developers use nvm / `setup-node` | keep `.nvmrc` as well, `mise.toml` is read only by mise |
| Personal, not committed settings | `mise.local.toml` (add to `.gitignore`) |

### Notes

- Without a version file the container works as before: base image only, no Node/Java.
- The `claude-devcontainer-mise` volume is shared by all containers. In a project without a version file, `node` may print a mise error ("no version set") instead of `command not found` if another project already installed it.
- The first install downloads the tools (Node ~30 s, JDK ~2 min); later starts reuse the cache (~1 s).
- Changed versions are picked up on the next container start (`docker start` re-runs the entrypoint); no image rebuild needed.
- To clear the cache: `docker volume rm claude-devcontainer-mise` (remove the containers using it first).

## SSH Agent Forwarding

The `--ssh` flag forwards your host's SSH agent into the container, allowing `git clone`, `git push`, and other SSH operations without copying private keys into the container.

| Platform | How it works |
|----------|-------------|
| **macOS** | Forwards SSH agent via Docker Desktop's `/run/host-services/ssh-auth.sock` |
| **Linux** | Forwards SSH agent via `$SSH_AUTH_SOCK` from the host |
| **Windows** | Not supported — Docker Desktop on Windows cannot forward the SSH agent socket |

> **Windows users:** SSH agent forwarding is not available. Use HTTPS instead — the container's git is preconfigured to use the GitHub CLI as credential helper, so log in once:
> ```bash
> gh auth login
> ```
> The login is persisted in `%USERPROFILE%\.config\gh-devcontainer` and survives `--recreate`. Use HTTPS remote URLs (`https://github.com/...`).

**Prerequisites (macOS/Linux):** your SSH agent must be running on the host with keys added (`ssh-add -l` to verify).

**Verify inside the container:**
```bash
ssh -T git@github.com
```

## How It Works

1. The Dockerfile builds an Ubuntu 24.04 image with the Claude Code native binary installed.
2. A non-root `dev` user is created for security.
3. Files under `rootfs/` are overlaid onto the image (path under `rootfs/` mirrors the path inside the container). The wrapper at `/usr/local/bin/claude` shadows the real binary in `PATH` and always passes `--dangerously-skip-permissions` and `--settings /usr/local/share/claude-devcontainer/settings.json` (container-only hooks, merged with your host settings). `/etc/gitconfig` sets `safe.directory = *` and `gh auth git-credential` as the credential helper.
4. On `docker run`, your local `~/.claude` config directory is mounted so Claude Code picks up your settings. `~/.gitconfig` (if present) and `~/.config/gh-devcontainer` are mounted as well.
5. With `--workspace <path>`, the host directory is mounted at `/home/dev/<basename>` and used as the container's `cwd`. The default container name is suffixed with the same basename so each project gets its own container.
6. If the host has `CLAUDE_CODE_OAUTH_TOKEN` set, the script writes it to `~/.config/claude-devcontainer/<container>.token` and bind-mounts it as `/run/secrets/claude_token` (read-only). The wrapper exports it back to the env only inside the `claude` process. On every re-run of the script the file is overwritten with the current host value; a `UserPromptSubmit` hook (`/usr/local/bin/claude-token-check`, loaded via `--settings`) warns when the running `claude` uses an outdated token and needs a restart.
7. The entrypoint `/usr/local/bin/devcontainer-init` runs `mise install` for the workspace (see [Project Tools](#project-tools-mise)) and then starts the shell.
8. The wrapper also self-heals `~/.claude.json` on each invocation, ensuring `hasCompletedOnboarding`, `lastOnboardingVersion`, and per-project `hasTrustDialogAccepted` are set.

## Related Projects

- [anthropics/claude-code](https://github.com/anthropics/claude-code) — Official Claude Code by Anthropic
- [Claude Code Docs: Dev Containers](https://code.claude.com/docs/en/devcontainer) — Official devcontainer documentation

## License

MIT
