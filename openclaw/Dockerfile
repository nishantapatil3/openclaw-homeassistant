# Use official OpenClaw image as base (multi-arch: amd64/aarch64)
FROM ghcr.io/openclaw/openclaw:latest

# Switch to root for package installation
USER root

# Set shell to bash (base OpenClaw image doesn't have /bin/sh)
SHELL ["/usr/bin/bash", "-c"]

# Install bashio and s6-overlay for Home Assistant compatibility
RUN apt-get update && apt-get install -y --no-install-recommends \
    bash \
    curl \
    jq \
    git \
    && mkdir -p /etc/cont-init.d \
    && mkdir -p /run/s6/container_environment \
    && git clone --depth 1 --branch v0.14.0 https://github.com/hassio-addons/bashio.git /usr/lib/bashio \
    && ln -s /usr/lib/bashio/lib/bashio /usr/bin/bashio \
    && if [ "$(uname -m)" = "aarch64" ]; then \
        S6_ARCH="aarch64"; \
    else \
        S6_ARCH="x86_64"; \
    fi \
    && curl -L -o /tmp/s6-overlay.tar.gz "https://github.com/just-containers/s6-overlay/releases/download/v2.2.0.3/s6-overlay-${S6_ARCH}.tar.gz" \
    && tar xzf /tmp/s6-overlay.tar.gz -C / \
    && rm /tmp/s6-overlay.tar.gz \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Copy Home Assistant add-on scripts
COPY rootfs/etc/cont-init.d/00-openclaw.sh /etc/cont-init.d/00-openclaw.sh
COPY rootfs/usr/bin/run-openclaw.sh /usr/bin/run-openclaw.sh
RUN chmod +x /etc/cont-init.d/00-openclaw.sh /usr/bin/run-openclaw.sh

# Create openclaw directory structure
RUN mkdir -p /home/node/.openclaw /home/node/workspace

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node /app/openclaw.mjs health --token "${OPENCLAW_GATEWAY_TOKEN:-healthcheck}" || exit 1

# Set working directory
WORKDIR /app

ENTRYPOINT ["/usr/bin/run-openclaw.sh"]
