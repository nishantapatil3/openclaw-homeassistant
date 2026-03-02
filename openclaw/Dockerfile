# Use official OpenClaw image as base
FROM ghcr.io/openclaw/openclaw:latest

# Switch to root for package installation
USER root

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install bashio and s6-overlay compatibility
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    jq \
    && mkdir -p /etc/cont-init.d \
    && mkdir -p /usr/bin \
    && mkdir -p /run/s6/container_environment \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Home Assistant add-on scripts
COPY rootfs/etc/cont-init.d/00-openclaw.sh /etc/cont-init.d/00-openclaw.sh
COPY rootfs/usr/bin/run-openclaw.sh /usr/bin/run-openclaw.sh
RUN chmod +x /etc/cont-init.d/00-openclaw.sh /usr/bin/run-openclaw.sh

# Create node user (for HA add-on compatibility, uid 1000)
# OpenClaw already runs as node user, so this is just for compatibility
RUN id -u node >/dev/null 2>&1 || useradd -m -u 1000 -s /bin/bash node

# Ensure OpenClaw directories exist and have correct permissions
RUN mkdir -p /home/node/.openclaw /home/node/workspace \
    && chown -R node:node /home/node/.openclaw /home/node/workspace

# Switch back to node user
USER node

# Health check (inherited from base image, but override for HA compatibility)
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node /opt/openclaw/openclaw.mjs health --token "${OPENCLAW_GATEWAY_TOKEN:-healthcheck}" || exit 1

# Set working directory
WORKDIR /opt/openclaw

ENTRYPOINT ["/usr/bin/run-openclaw.sh"]
