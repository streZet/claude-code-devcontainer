# Claude Code DevContainer - Dockerized AI Coding Assistant Environment

[![Docker](https://img.shields.io/badge/Docker-Required-blue?logo=docker)](https://www.docker.com/)
[![Ubuntu](https://img.shields.io/badge/Ubuntu-24.04-orange?logo=ubuntu)](https://ubuntu.com/)
[![Node.js](https://img.shields.io/badge/Node.js-22-green?logo=node.js)](https://nodejs.org/)
[![License: MIT](https://img.shields.io/badge/License-MIT-yellow.svg)](LICENSE)

A ready-to-use Docker container with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) pre-installed on Ubuntu 24.04. Run Anthropic's AI coding assistant in an isolated, reproducible environment on Linux, macOS, or Windows.

## The Problem

Claude Code is designed for Linux and macOS. On Windows, many tools and shell scripts that Claude Code relies on **don't work correctly** — bash commands fail, file permissions behave differently, and Unix-specific utilities are missing. On any OS, running `--dangerously-skip-permissions` is risky since Claude Code gets unrestricted access to your entire host system.

This project solves both problems: Claude Code runs inside a Linux container where all tools and scripts work correctly, and `--dangerously-skip-permissions` is safely sandboxed — the container isolates it from your host machine.

## Why Use This?

- **Fixes Claude Code on Windows** — eliminates shell compatibility issues, broken scripts, and missing Unix tools
- **Safe `--dangerously-skip-permissions`** — run fully autonomous Claude Code sessions sandboxed inside the container, without risking your host system
- **Zero setup** — build and run with a single command, no manual Node.js or npm configuration needed
- **Isolated environment** — keep your host system clean; all dependencies live inside the container
- **Cross-platform** — works on Linux, macOS, and Windows with provided shell and batch scripts
- **Mount your projects** — work on existing local codebases without copying files into the container
- **Persistent config** — your `~/.claude` settings are mounted automatically and survive container restarts

## What's Inside

| Component | Details |
|-----------|---------|
| **OS** | Ubuntu 24.04 LTS |
| **Node.js** | 22 (via NodeSource) |
| **Claude Code** | `@anthropic-ai/claude-code` (globally installed) |
| **User** | Non-root `dev` with passwordless sudo |
| **Tools** | git, ssh, curl, wget, jq, vim, python3, htop, tree, unzip, tar, less, dnsutils |
| **Port** | 3000 exposed |

## Quick Start

### Prerequisites

- [Docker](https://docs.docker.com/get-docker/) installed and running
- An [Anthropic API key](https://console.anthropic.com/) for Claude Code authentication

### Build

```bash
# Linux / macOS
./docker-build.sh

# Windows
docker-build.bat
```

### Run

```bash
# Linux / macOS
./docker-run.sh [--workspace <path>] [--name <container-name>]

# Windows
docker-run.bat [--workspace <path>] [--name <container-name>]
```

| Option | Description | Default |
|--------|-------------|---------|
| `--workspace` | Local directory to mount to `/home/dev/workspace` | none |
| `--name` | Custom Docker container name | `claude-code-development` |

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
```

## Volume Mounts

| Host | Container | Description |
|------|-----------|-------------|
| `~/.claude` (Linux/macOS) or `%USERPROFILE%\.claude` (Windows) | `/home/dev/.claude` | Claude Code configuration (always mounted) |
| Optional path argument | `/home/dev/workspace` | Your projects directory |

## How It Works

1. The Dockerfile builds an Ubuntu 24.04 image with Node.js 22 and Claude Code globally installed
2. A non-root `dev` user is created for security
3. On `docker run`, your local `~/.claude` config directory is mounted so Claude Code picks up your API key and settings
4. Optionally mount any local directory as the workspace to use Claude Code on your existing projects

## Related Projects

- [anthropics/claude-code](https://github.com/anthropics/claude-code) — Official Claude Code by Anthropic
- [Claude Code Docs: Dev Containers](https://code.claude.com/docs/en/devcontainer) — Official devcontainer documentation

## License

MIT
