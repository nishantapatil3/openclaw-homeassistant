#!/usr/bin/with-contenv bashio
set -e

# Log start
bashio::log.info "Initializing OpenClaw AI add-on..."

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

chown node:node "$CONFIG_FILE"

# Set permissions
chown -R node:node /home/node/.openclaw
chown -R node:node /home/node/workspace

# Handle extra apt packages if specified
if bashio::config.has_value 'extra_apt_packages'; then
    EXTRA_PACKAGES=$(bashio::config 'extra_apt_packages')
    if [ -n "$EXTRA_PACKAGES" ]; then
        bashio::log.info "Installing extra apt packages: $EXTRA_PACKAGES"
        apt-get update && apt-get install -y --no-install-recommends $EXTRA_PACKAGES || bashio::log.warning "Failed to install some packages"
    fi
fi

# Export environment variables for OpenClaw
export OPENCLAW_HOME_VOLUME="openclaw_home"
export PLAYWRIGHT_BROWSERS_PATH="/home/node/.cache/ms-playwright"

# Handle extra mounts if specified
if bashio::config.has_value 'extra_mounts'; then
    EXTRA_MOUNTS=$(bashio::config 'extra_mounts')
    if [ -n "$EXTRA_MOUNTS" ]; then
        export OPENCLAW_EXTRA_MOUNTS="$EXTRA_MOUNTS"
        bashio::log.info "Configured extra mounts: $EXTRA_MOUNTS"
    fi
fi

# Set sandbox configuration
SANDBOX_MEMORY=$(bashio::config 'sandbox_memory')
SANDBOX_MEMORY_SWAP=$(bashio::config 'sandbox_memory_swap')
SANDBOX_CPUS=$(bashio::config 'sandbox_cpus')

export OPENCLAW_SANDBOX_MEMORY="${SANDBOX_MEMORY:-1g}"
export OPENCLAW_SANDBOX_MEMORY_SWAP="${SANDBOX_MEMORY_SWAP:-2g}"
export OPENCLAW_SANDBOX_CPUS="${SANDBOX_CPUS:-1}"

bashio::log.info "OpenClaw AI initialization complete"
