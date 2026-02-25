# Claude Code Development Container

Docker container with [Claude Code](https://docs.anthropic.com/en/docs/claude-code) pre-installed on Ubuntu 24.04.

## What's Inside

- Ubuntu 24.04
- Node.js 22
- Git, SSH, sudo
- Claude Code (`@anthropic-ai/claude-code`)
- Non-root user `dev` with passwordless sudo
- Utilities: curl, wget, jq, vim, unzip, tar, htop, tree, less, python3, dnsutils

## Build

```bash
# Linux/Mac
./docker-build.sh

# Windows
docker-build.bat
```

## Run

### Empty workspace

```bash
# Linux/Mac
./docker-run.sh

# Windows
docker-run.bat
```

Starts the container with an empty `/home/dev/workspace` directory where you can clone projects.

### Mount a directory

```bash
# Linux/Mac
./docker-run.sh /path/to/your/workspace

# Windows
docker-run.bat C:\path\to\your\workspace
```

Mounts the specified directory to `/home/dev/workspace` inside the container. You can mount a single project or an entire directory with multiple projects.

## Volume Mounts

| Host | Container | Description |
|------|-----------|-------------|
| `~/.claude` (Linux/Mac) or `%USERPROFILE%\.claude` (Windows) | `/home/dev/.claude` | Claude Code configuration (always mounted) |
| Optional path argument | `/home/dev/workspace` | Your projects directory |
