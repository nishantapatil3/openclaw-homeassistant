# OpenClaw Home Assistant Add-on Package

This directory contains the Home Assistant add-on package for OpenClaw.

## Contents

- `config.yaml`: Home Assistant add-on metadata, options, and schema.
- `build.yaml`: Build metadata for Home Assistant add-on builder.
- `Dockerfile`: Add-on container image definition.
- `rootfs/`: Add-on runtime scripts copied into the container.
  - `etc/cont-init.d/00-openclaw.sh`: Pre-start init logic.
  - `usr/bin/run-openclaw.sh`: Main entrypoint script.

## Current Runtime Behavior

- Uses upstream `ghcr.io/openclaw/openclaw:latest` as base image.
- Persists OpenClaw state in `/home/node/.openclaw`.
- Serves Control UI on port `18789`.
- Logs a tokenized UI URL on startup:
  - `http://<your-hassio-ip>:18789/?token=<token>`

## Add-on Options

Configured in `config.yaml`:

- `gateway_token`: Optional fixed gateway token.
- `allow_insecure_control_ui_auth`: Control UI insecure auth fallback.
- `dangerously_disable_control_ui_device_auth`: Disables Control UI device auth checks.
- `extra_apt_packages`, `extra_mounts`
- `sandbox_memory`, `sandbox_memory_swap`, `sandbox_cpus`

## Local Build/Test

From repository root:

```bash
docker build -t openclaw-ha:test ./openclaw
docker run -d --name openclaw-ha-smoke -p 18789:18789 openclaw-ha:test
docker logs -f openclaw-ha-smoke
curl -i http://127.0.0.1:18789
```

Cleanup:

```bash
docker rm -f openclaw-ha-smoke
```

## Release Reminder

When cutting a release, update `openclaw/config.yaml` version first, then tag and publish.
