ARG BUILD_FROM
FROM ${BUILD_FROM}

# Set shell
SHELL ["/bin/bash", "-o", "pipefail", "-c"]

# Install required packages
RUN apt-get update && apt-get install -y --no-install-recommends \
    curl \
    ca-certificates \
    gnupg \
    && mkdir -p /etc/apt/keyrings \
    && curl -fsSL https://deb.nodesource.com/gpgkey/nodesource-repo.gpg.key | gpg --dearmor -o /etc/apt/keyrings/nodesource.gpg \
    && echo "deb [signed-by=/etc/apt/keyrings/nodesource.gpg] https://deb.nodesource.com/node_20.x nodistro main" | tee /etc/apt/sources.list.d/nodesource.list \
    && apt-get update \
    && apt-get install -y nodejs \
    && apt-get clean \
    && rm -rf /var/lib/apt/lists/*

# Create node user
RUN useradd -m -u 1000 -s /bin/bash node

# Set working directory
WORKDIR /home/node

# Clone OpenClaw repository
RUN git clone https://github.com/openclaw/openclaw.git /opt/openclaw \
    && chown -R node:node /opt/openclaw

USER node
WORKDIR /opt/openclaw

# Install dependencies
RUN npm install -g pnpm \
    && pnpm install --frozen-lockfile

# Expose ports
EXPOSE 18789 1455

# Copy entrypoint script
COPY rootfs/etc/cont-init.d/00-openclaw.sh /etc/cont-init.d/00-openclaw.sh
COPY rootfs/usr/bin/run-openclaw.sh /usr/bin/run-openclaw.sh

RUN chmod +x /etc/cont-init.d/00-openclaw.sh /usr/bin/run-openclaw.sh

# Set working directory
WORKDIR /opt/openclaw

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
    CMD node dist/index.js health --token "${OPENCLAW_GATEWAY_TOKEN:-healthcheck}" || exit 1

ENTRYPOINT ["/usr/bin/run-openclaw.sh"]
