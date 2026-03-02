# OpenClaw AI - Home Assistant Add-on

OpenClaw AI add-on for Home Assistant.

## Quick Install (Home Assistant)

1. Copy this repo's `openclaw` folder to your HA add-ons path:
   - Target: `/addon_configs/openclaw`
2. In Home Assistant: **Settings** -> **Add-ons** -> **Add-on Store** -> menu (⋮) -> **Repositories**.
3. Add repository path: `/addon_configs/openclaw`.
4. Open **OpenClaw AI** in the store and click **Install**.
5. Start the add-on and open:
   - `http://<your-hassio-ip>:18789`

## Minimal Setup

1. Set a fixed token in add-on options (recommended):

```yaml
gateway_token: "replace-with-a-long-random-token"
```

2. Restart the add-on.
3. Open UI with token:
   - `http://<your-hassio-ip>:18789/?token=<gateway_token>`

## Add-on Options

| Option | Purpose | Default |
|---|---|---|
| `gateway_token` | Fixed gateway auth token for Control UI | `""` |
| `allow_insecure_control_ui_auth` | Relax Control UI auth checks | `false` |
| `dangerously_disable_control_ui_device_auth` | Disable Control UI pairing/device auth checks | `false` |
| `extra_apt_packages` | Extra apt packages to install | `""` |
| `extra_mounts` | Extra bind mounts (`source:target[:options]`) | `""` |
| `sandbox_memory` | Sandbox memory limit | `"1g"` |
| `sandbox_memory_swap` | Sandbox swap limit | `"2g"` |
| `sandbox_cpus` | Sandbox CPU limit | `1` |

## Useful Commands

```bash
# Print dashboard URL
docker exec -it addon_openclaw pnpm run cli dashboard --no-open

# List/approve devices
docker exec -it addon_openclaw pnpm run cli devices list
docker exec -it addon_openclaw pnpm run cli devices approve <requestId>

# Health check
docker exec -it addon_openclaw node dist/index.js health --token "$OPENCLAW_GATEWAY_TOKEN"
```

## Troubleshooting

- `token mismatch`:
  - set `gateway_token`, restart add-on, open `/?token=<gateway_token>`.
- `pairing required`:
  - enable `allow_insecure_control_ui_auth`.
  - if still blocked, enable `dangerously_disable_control_ui_device_auth` (trusted LAN only).

## Links

- OpenClaw docs: https://docs.openclaw.ai
- Upstream project: https://github.com/openclaw/openclaw
