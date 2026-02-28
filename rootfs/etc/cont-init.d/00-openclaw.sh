#!/usr/bin/with-contenv bashio
set -e

# Log start
bashio::log.info "Initializing OpenClaw AI add-on..."

# Create configuration directories if they don't exist
mkdir -p /home/node/.openclaw
mkdir -p /home/node/workspace

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
