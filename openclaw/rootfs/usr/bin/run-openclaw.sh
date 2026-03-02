#!/usr/bin/with-contenv bashio
set -e

# Change to OpenClaw directory (upstream installs in /app)
cd /app

# Force OpenClaw state/config under the persisted Home Assistant volume.
export HOME="/home/node"
export OPENCLAW_STATE_DIR="/home/node/.openclaw"
export OPENCLAW_CONFIG_PATH="/home/node/.openclaw/openclaw.json"

# Create configuration directories if they don't exist
mkdir -p /home/node/.openclaw
mkdir -p /home/node/workspace

# Ensure runtime config exists at the path OpenClaw reads.
CONFIG_FILE="/home/node/.openclaw/openclaw.json"
if [ ! -f "$CONFIG_FILE" ]; then
    bashio::log.info "Creating default OpenClaw configuration..."
    echo '{}' > "$CONFIG_FILE"
fi

# Keep LAN access working unless explicit origins are configured.
if ! jq -e '.gateway.controlUi.allowedOrigins != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    TMP_CONFIG="$(mktemp)"
    jq '.gateway.controlUi.dangerouslyAllowHostHeaderOriginFallback = true' "$CONFIG_FILE" > "$TMP_CONFIG"
    mv "$TMP_CONFIG" "$CONFIG_FILE"
fi

# Force Control UI no-pairing behavior for add-on UX (security tradeoff).
TMP_CONFIG="$(mktemp)"
jq '.gateway.controlUi.allowInsecureAuth = true | .gateway.controlUi.dangerouslyDisableDeviceAuth = true' "$CONFIG_FILE" > "$TMP_CONFIG"
mv "$TMP_CONFIG" "$CONFIG_FILE"

# If configured, pin gateway auth token to avoid Control UI token mismatch.
if bashio::config.has_value 'gateway_token'; then
    GATEWAY_TOKEN="$(bashio::config 'gateway_token')"
    if [ -n "$GATEWAY_TOKEN" ]; then
        TMP_CONFIG="$(mktemp)"
        jq --arg token "$GATEWAY_TOKEN" \
            '.gateway.auth.mode = "token" | .gateway.auth.token = $token | del(.gateway.auth.password)' \
            "$CONFIG_FILE" > "$TMP_CONFIG"
        mv "$TMP_CONFIG" "$CONFIG_FILE"
        bashio::log.info "Using gateway token from add-on configuration."
    fi
fi

# Ensure a stable token exists before gateway starts to avoid UI mismatch loops.
if ! jq -e '.gateway.auth.token != null and (.gateway.auth.token | tostring | length) > 0' "$CONFIG_FILE" >/dev/null 2>&1; then
    GENERATED_TOKEN="$(node -e "console.log(require('node:crypto').randomBytes(24).toString('hex'))")"
    TMP_CONFIG="$(mktemp)"
    jq --arg token "$GENERATED_TOKEN" \
        '.gateway.auth.mode = "token" | .gateway.auth.token = $token | del(.gateway.auth.password)' \
        "$CONFIG_FILE" > "$TMP_CONFIG"
    mv "$TMP_CONFIG" "$CONFIG_FILE"
fi

# Helpful log for fixing Control UI token mismatch.
ACTIVE_TOKEN="$(jq -r '.gateway.auth.token // empty' "$CONFIG_FILE" 2>/dev/null || true)"
if [ -n "$ACTIVE_TOKEN" ]; then
    bashio::log.info "Gateway token: $ACTIVE_TOKEN"
    bashio::log.info "Open Control UI with token: http://<your-hassio-ip>:18789/?token=$ACTIVE_TOKEN"
fi
bashio::log.warning "Control UI insecure auth path enabled (allowInsecureAuth=true)."
bashio::log.warning "Control UI device auth is DISABLED (dangerouslyDisableDeviceAuth=true)."

# Check if onboarding is complete
if ! jq -e '.gateway.auth.token != null' "$CONFIG_FILE" >/dev/null 2>&1; then
    bashio::log.warning "OpenClaw not configured yet."
    bashio::log.warning "Run the onboarding process using the CLI:"
    bashio::log.warning "  docker exec -it addon_openclaw openclaw onboard"
    bashio::log.warning "Or access the web UI at http://<your-hassio-ip>:18789"
fi

# Start the gateway (bind to LAN for container access)
bashio::log.info "Starting OpenClaw Gateway on port 18789..."
exec node openclaw.mjs gateway --port 18789 --allow-unconfigured --bind lan
