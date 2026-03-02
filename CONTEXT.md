# OpenClaw Home Assistant Add-on - Context

## Overview
This repository contains the Home Assistant add-on configuration for **OpenClaw AI** - a self-hosted personal AI assistant that connects to messaging platforms (WhatsApp, Telegram, Slack, Discord, Signal, iMessage, Microsoft Teams, etc.) and provides voice interaction, visual Canvas workspace, and extensible skills.

## Repository
- **GitHub**: https://github.com/nishantpatil3/openclaw-homeassistant
- **Add-on Image**: `ghcr.io/nishantpatil3/openclaw-{arch}`
- **Documentation**: https://docs.openclaw.ai
- **Upstream**: https://github.com/openclaw/openclaw

### Versioning
This project uses two separate versioning schemes:

| Version Type | Format | Example | Location |
|--------------|--------|---------|----------|
| **OpenClaw Upstream** | Date-based `YYYY.M.D` | `openclaw 2026.2.26` | Cloned from upstream repo |
| **Home Assistant Add-on** | Semantic `MAJOR.MINOR.PATCH` | `1.0.14` | `openclaw/config.yaml` |

- **Upstream version**: Tracks the OpenClaw project release (date-based)
- **Add-on version**: Tracks Home Assistant add-on specific changes and fixes

## Architecture
The add-on uses the official prebuilt OpenClaw image with Home Assistant integration:
- **Base Image**: `ghcr.io/openclaw/openclaw:latest` (official multi-arch)
- **Runtime**: Node.js 22 on Debian Bookworm (from OpenClaw base)
- **HA Integration**: bashio for configuration, s6-overlay v3 for lifecycle
- **Ports**: 
  - `18789/tcp` - OpenClaw Gateway Web UI
  - `1455/tcp` - OAuth callback for OpenAI Codex

### Build Approach
- **Prebuilt binaries**: Uses official OpenClaw image with pre-compiled native modules
- **Multi-arch native**: amd64 and aarch64 supported without QEMU emulation
- **Build time**: ~2-3 minutes (vs 15+ min when building from source)

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

### GitHub CLI (gh) Commands
The `gh` command-line tool is used for GitHub operations:
```bash
# Create releases
gh release create v1.0.13 --title "v1.0.13" --notes "..."

# View releases
gh release list
gh release view v1.0.13

# Manage issues and PRs
gh issue create
gh pr create
gh pr list

# Run GitHub Actions workflows
gh workflow run build.yaml
gh run list
gh run watch

# Repository management
gh repo view
gh repo sync
```

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.15 | 2026-03-02 | Use prebuilt OpenClaw image (ghcr.io/openclaw/openclaw:latest) |
| 1.0.14 | 2026-03-02 | Add build-essential for node-llama-cpp compilation |
| 1.0.13 | 2026-03-01 | Upgrade Node.js to 22.x (required by OpenClaw) |
| 1.0.12 | 2026-03-01 | Fix pnpm install using corepack for correct version |
| 1.0.11 | 2026-03-01 | Fix Docker build: ARG default, remove --frozen-lockfile |
| 1.0.10 | 2026-03-01 | Fix s6-overlay v3 compatibility, base image to bullseye |
| 1.0.9 | - | Previous release |

## Known Issues & Fixes

### Prebuilt Image Approach (v1.0.15+)
**Architecture**: Using `ghcr.io/openclaw/openclaw:latest` as base image

**Benefits**:
- Fast builds (~2-3 min vs 15+ min)
- Native multi-arch support (no QEMU emulation)
- Pre-compiled native modules (llama.cpp, etc.)
- Tracks latest OpenClaw releases automatically

**Considerations**:
- Base image is Debian Bookworm (not Bullseye)
- To pin specific OpenClaw version, update `FROM` line in Dockerfile

### Build Tools Required (v1.0.14 and earlier)
**Issue**: `node-llama-cpp` postinstall fails with "C++ Compiler toolset is not available"

**Cause**: llama.cpp needs to compile from source, requiring g++ and make

**Fix** (v1.0.14+): Install `build-essential` package

**Note**: Resolved in v1.0.15+ by using prebuilt image

### Node.js Version Requirement (v1.0.13 and earlier)
**Issue**: Build/runtime failures due to incompatible Node.js version

**Cause**: OpenClaw requires Node.js >= 22

**Fix**: Use NodeSource 22.x repository instead of 20.x

**Note**: Resolved in v1.0.15+ (base image includes Node.js 22)

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
