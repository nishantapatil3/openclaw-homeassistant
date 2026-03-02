# OpenClaw AI - Home Assistant Add-on

[OpenClaw AI](https://docs.openclaw.ai) is an AI-powered automation gateway for messaging platforms including WhatsApp, Telegram, Discord, and more.

## Features

- 🤖 AI-powered automation gateway
- 📱 Multi-platform messaging support (WhatsApp, Telegram, Discord)
- 🔐 Secure OAuth integration with OpenAI Codex
- 🏖️ Isolated agent sandboxing with configurable resources
- 📊 Web-based dashboard for management
- 🔌 Easy integration with Home Assistant

## Installation

This add-on is installed locally on your Home Assistant instance.

### Prerequisites

- Home Assistant OS or Home Assistant Supervised
- Access to the Home Assistant file system (via SSH, Samba, or File Editor add-on)
- At least 2 GB of available RAM

### Step 1: Copy the Add-on Files

Copy the `openclaw` folder to your Home Assistant add-ons configuration directory:

**Via SSH/Terminal:**
```bash
# Navigate to your Home Assistant config directory
cd /config

# Copy the openclaw folder to add-ons
cp -r /path/to/openclaw /addon_configs/openclaw
```

**Via Samba/File Editor:**
1. Open your Home Assistant `config` folder in your file browser
2. Copy the entire `openclaw` folder
3. Paste it into the `/addon_configs/` directory

### Step 2: Add the Local Repository

1. In Home Assistant, navigate to **Settings** → **Add-ons**

2. Click the **Add-on Store** button (bottom right)

3. Click the three dots menu (⋮) in the top right corner

4. Select **Repositories**

5. Click **Add** and enter: `/addon_configs/openclaw`

6. Click **Add** to confirm

### Step 3: Install the Add-on

1. The **OpenClaw AI** add-on should now appear in the add-on store

2. Click on it and press **Install**

3. Wait for the installation to complete (this may take a few minutes on first install)

## Configuration

### Add-on Configuration Options

| Option | Description | Default |
|--------|-------------|---------|
| `gateway_token` | Fixed gateway token used by Control UI authentication | `""` (auto-generated) |
| `allow_insecure_control_ui_auth` | Allow insecure Control UI auth fallback (can reduce pairing prompts on plain HTTP) | `false` |
| `dangerously_disable_control_ui_device_auth` | Disable Control UI device auth/pairing checks (high risk) | `false` |
| `extra_apt_packages` | Space-separated list of additional apt packages to install | `""` |
| `extra_mounts` | Comma-separated bind mounts (source:target[:options]) | `""` |
| `sandbox_memory` | Memory limit for agent sandboxes | `"1g"` |
| `sandbox_memory_swap` | Memory swap limit for agent sandboxes | `"2g"` |
| `sandbox_cpus` | CPU limit for agent sandboxes | `1` |

### Example Configuration

```yaml
gateway_token: "replace-with-a-long-random-token"
allow_insecure_control_ui_auth: false
dangerously_disable_control_ui_device_auth: false
extra_apt_packages: "ffmpeg build-essential"
extra_mounts: "/media:/home/node/media:ro"
sandbox_memory: "2g"
sandbox_memory_swap: "4g"
sandbox_cpus: 2
```

If you see `unauthorized: gateway token mismatch`, set `gateway_token` to a fixed value and restart the add-on, then paste that token into Control UI settings.
For this add-on, gateway auth cannot be fully disabled while binding to LAN (`--bind lan`); OpenClaw requires auth for non-loopback binds.
If you see `pairing required`, you can set `allow_insecure_control_ui_auth: true`, and if still needed use `dangerously_disable_control_ui_device_auth: true` (not recommended for untrusted networks).

## Ports

| Port | Description |
|------|-------------|
| 18789 | OpenClaw Gateway Web UI |
| 1455 | OAuth callback for OpenAI Codex |

## First-Time Setup

1. **Start the add-on** from the Home Assistant Supervisor panel

2. **Access the Web UI** at `http://<your-hassio-ip>:18789`

3. **Run the onboarding process**:
   - Via CLI (using Home Assistant SSH or Terminal):
     ```bash
     docker exec -it addon_openclaw pnpm run cli onboard
     ```
   - Or follow the onboarding wizard in the Web UI

4. **Configure messaging channels**:
   - **WhatsApp**: `docker exec -it addon_openclaw pnpm run cli channels login`
   - **Telegram**: `docker exec -it addon_openclaw pnpm run cli channels add --channel telegram --token "<bot_token>"`
   - **Discord**: `docker exec -it addon_openclaw pnpm run cli channels add --channel discord --token "<bot_token>"`

## Useful Commands

All commands should be run via the add-on's CLI:

```bash
# Get dashboard URL
docker exec -it addon_openclaw pnpm run cli dashboard --no-open

# List connected devices
docker exec -it addon_openclaw pnpm run cli devices list

# Approve a device
docker exec -it addon_openclaw pnpm run cli devices approve <requestId>

# Health check
docker exec -it addon_openclaw node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

## Volumes

| Path | Description |
|------|-------------|
| `/addon_configs/openclaw` | Configuration directory (mapped to `/home/node/.openclaw`) |
| `/addon_configs/openclaw/workspace` | Workspace directory (mapped to `/home/node/workspace`) |

## Resource Requirements

- **RAM**: At least 2 GB recommended (pnpm install may fail on 1 GB hosts)
- **Disk**: Sufficient space for Docker images and logs (~2-5 GB recommended)
- **Architecture**: amd64, arm64

## Security Considerations

- The add-on runs as a non-root user (`node`, uid 1000)
- Agent sandboxes run with restricted capabilities by default
- Network access for sandboxes is disabled by default
- Configure appropriate firewall rules for exposed ports

## Troubleshooting

### Add-on fails to start

1. Check the add-on logs in Home Assistant Supervisor
2. Ensure you have sufficient memory available (at least 2 GB)
3. Verify the configuration directories exist and have correct permissions

### Onboarding fails

1. Ensure the add-on has fully started
2. Check network connectivity from your Home Assistant instance
3. Review the logs for specific error messages

### Permission issues on Linux

If you encounter permission issues, run:
```bash
sudo chown -R 1000:1000 /addon_configs/openclaw
```

## Support

- **Documentation**: https://docs.openclaw.ai
- **GitHub**: https://github.com/openclaw/openclaw
- **Issues**: Report add-on specific issues in the add-on repository

## License

This add-on is provided as-is. OpenClaw AI is subject to its own license terms.

## Changelog

### 1.0.0
- Initial release
- Support for OpenClaw Gateway
- Web UI access on port 18789
- OAuth callback support on port 1455
- Configurable sandbox resources
- Extra mount support
