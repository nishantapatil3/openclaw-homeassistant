# OpenClaw Home Assistant Add-on - Context

## Overview
This repository contains the Home Assistant add-on configuration for **OpenClaw AI** - a self-hosted personal AI assistant that connects to messaging platforms (WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Microsoft Teams, etc.) and provides voice interaction, visual Canvas workspace, and extensible skills.

## Repository
- **GitHub**: https://github.com/nishantpatil3/openclaw-homeassistant
- **Add-on Image**: `ghcr.io/nishantpatil3/openclaw-{arch}`
- **Documentation**: https://docs.openclaw.ai
- **Upstream**: https://github.com/openclaw/openclaw

## Architecture
The add-on is built using the Home Assistant add-on framework with:
- **Base Image**: Debian Bullseye (Home Assistant official base images)
- **s6-overlay**: v3 (init system for container lifecycle management)
- **Runtime**: Node.js 22.x with pnpm (corepack)
- **Ports**: 
  - `18789/tcp` - OpenClaw Gateway Web UI
  - `1455/tcp` - OAuth callback for OpenAI Codex

## Directory Structure
```
openclaw/
├── config.yaml          # Add-on configuration (version, ports, volumes, schema)
├── build.yaml           # Build configuration (base images per architecture)
├── Dockerfile           # Container build instructions
└── rootfs/
    ├── etc/
    │   └── cont-init.d/
    │       └── 00-openclaw.sh    # Initialization script (runs at container start)
    └── usr/
        └── bin/
            └── run-openclaw.sh   # Entry point script (runs the application)
```

## Key Configuration

### Volumes
- `/addon_configs/openclaw:/home/node/.openclaw:rw` - Configuration storage
- `/addon_configs/openclaw/workspace:/home/node/workspace:rw` - Workspace storage

### Environment Variables (exported by init script)
- `OPENCLAW_HOME_VOLUME` - Home volume identifier
- `PLAYWRIGHT_BROWSERS_PATH` - Playwright browser cache location
- `OPENCLAW_SANDBOX_MEMORY` - Sandbox memory limit (default: 1g)
- `OPENCLAW_SANDBOX_MEMORY_SWAP` - Sandbox swap limit (default: 2g)
- `OPENCLAW_SANDBOX_CPUS` - Sandbox CPU limit (default: 1)
- `OPENCLAW_EXTRA_MOUNTS` - Optional extra mount configurations

### OpenClaw CLI Commands
The add-on includes the full OpenClaw CLI for management:
```bash
# Onboarding (first-time setup)
pnpm run cli onboard

# Gateway management
pnpm run cli gateway probe
pnpm run cli devices list
pnpm run cli devices approve <requestId>

# Channel setup
pnpm run cli channels login        # WhatsApp QR
pnpm run cli channels add --channel telegram --token "<token>"

# Dashboard (generates pairing token)
pnpm run cli dashboard --no-open
```

### Gateway Token & Pairing
- The Web UI at port 18789 requires a gateway token for authentication
- Token is generated during onboarding or via `dashboard` command
- If seeing "unauthorized" or "disconnected (1008): pairing required":
  1. Run `pnpm run cli dashboard --no-open`
  2. Use the displayed token in the Web UI

### Agent Sandbox
Non-main agent sessions can run in Docker sandboxes for isolation:
- Configured via `agents.defaults.sandbox` in config
- Sandbox images built via upstream scripts
- Tool policy: `deny` wins over `allow`

## Release Process

1. Update version in `openclaw/config.yaml`
2. Commit changes with descriptive message
3. Create annotated tag: `git tag -a v<version> -m "Release version <version>"`
4. Push: `git push origin main v<version>`
5. Create GitHub release: `gh release create v<version> --title "v<version>" --notes "..."`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.13 | 2026-03-01 | Upgrade Node.js to 22.x (required by OpenClaw) |
| 1.0.12 | 2026-03-01 | Fix pnpm install using corepack for correct version |
| 1.0.11 | 2026-03-01 | Fix Docker build: ARG default, remove --frozen-lockfile |
| 1.0.10 | 2026-03-01 | Fix s6-overlay v3 compatibility, base image to bullseye |
| 1.0.9 | - | Previous release |

## Known Issues & Fixes

### Node.js Version Requirement (v1.0.13)
**Issue**: Build/runtime failures due to incompatible Node.js version

**Cause**: OpenClaw requires Node.js >= 22

**Fix**: Use NodeSource 22.x repository instead of 20.x

### pnpm Install Failure (v1.0.12)
**Issue**: `pnpm install --frozen-lockfile` fails during build

**Cause**: 
1. Global pnpm version mismatch with `package.json` `packageManager` field
2. Shallow git clone may not include pnpm-lock.yaml

**Fix**: 
- Use `corepack enable pnpm` for correct version from package.json
- Full git clone (not --depth 1)

### s6-overlay v3 Compatibility (v1.0.10)
**Issue**: `s6-envdir: fatal: unable to envdir /run/s6/container_environment: No such file or directory`

**Cause**: Newer Home Assistant base images use s6-overlay v3, which has different environment directory structure than v2.

**Fix**: 
- Create `/run/s6/container_environment` directory in Dockerfile
- Use `bullseye` base image (not `bookworm`)

## Build & Publish Workflows
GitHub Actions workflows are configured in `.github/workflows/`:
- `build.yaml` - Builds the add-on for all architectures
- `publish.yaml` - Publishes to container registry

## User Configuration Options
Users can configure via Home Assistant UI:
- `extra_apt_packages` - Additional apt packages to install
- `extra_mounts` - Additional volume mounts
- `sandbox_memory` - Memory limit for sandbox
- `sandbox_memory_swap` - Swap limit for sandbox
- `sandbox_cpus` - CPU limit for sandbox

## Important Notes

1. **Permissions**: The container runs as `node` (uid 1000). Host bind mounts should be owned by uid 1000 to avoid permission errors.

2. **Gateway bind**: Defaults to `lan` for container use (`OPENCLAW_GATEWAY_BIND`).

3. **Session storage**: Gateway container is source of truth for sessions (`~/.openclaw/agents/<agentId>/sessions/`).

4. **Memory**: At least 2 GB RAM recommended for pnpm install (may OOM-kill on 1 GB hosts).

5. **Health check**: 
   ```bash
   node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
   ```

## Supported Channels
- WhatsApp (QR code pairing)
- Telegram (bot token)
- Discord (bot token)
- Slack
- Signal
- iMessage (BlueBubbles)
- Microsoft Teams
- Matrix
- Google Chat
- Zalo
- WebChat
