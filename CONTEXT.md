# OpenClaw Home Assistant Add-on - Context

## Overview
This repository contains the Home Assistant add-on configuration for **OpenClaw AI** - an AI-powered automation gateway for messaging platforms.

## Repository
- **GitHub**: https://github.com/nishantpatil3/openclaw-homeassistant
- **Add-on Image**: `ghcr.io/nishantpatil3/openclaw-{arch}`
- **Documentation**: https://docs.openclaw.ai

## Architecture
The add-on is built using the Home Assistant add-on framework with:
- **Base Image**: Debian Bullseye (Home Assistant official base images)
- **s6-overlay**: v3 (init system for container lifecycle management)
- **Runtime**: Node.js 20.x with pnpm
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

## Release Process

1. Update version in `openclaw/config.yaml`
2. Commit changes with descriptive message
3. Create annotated tag: `git tag -a v<version> -m "Release version <version>"`
4. Push: `git push origin main v<version>`
5. Create GitHub release: `gh release create v<version> --title "v<version>" --notes "..."`

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0.10 | 2026-03-01 | Fix s6-overlay v3 compatibility, base image to bullseye |
| 1.0.9 | - | Previous release |

## Known Issues & Fixes

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
