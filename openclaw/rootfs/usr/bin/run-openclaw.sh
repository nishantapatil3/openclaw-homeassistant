#!/usr/bin/with-contenv bashio
set -e

# Change to OpenClaw directory
cd /opt/openclaw

# Check if onboarding is complete
if [ ! -f "/home/node/.openclaw/config.json" ]; then
    bashio::log.warning "OpenClaw not configured yet."
    bashio::log.warning "Run the onboarding process using the CLI:"
    bashio::log.warning "  docker exec -it addon_openclaw openclaw onboard"
    bashio::log.warning "Or access the web UI at http://<your-hassio-ip>:18789"
fi

# Start the gateway
bashio::log.info "Starting OpenClaw Gateway on port 18789..."
exec node openclaw.mjs gateway --port 18789 --allow-unconfigured
