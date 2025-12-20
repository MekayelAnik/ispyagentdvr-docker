#!/bin/bash

# Exit on error and print each command for debugging
set -ex

# Set variables
REPO_NAME='ispyagentdvr-docker'
DOCKERFILE_NAME="Dockerfile.$REPO_NAME"

# Check for required build data
if [ ! -e ./resources/build_data/base-image ] || [ ! -e ./resources/build_data/version ]; then
    echo "Could not find required build data files. Exiting..."
    exit 1
fi

BASE_IMAGE=$(cat ./resources/build_data/base-image)
AGENTDVR_VERSION=$(cat ./resources/build_data/version)
AGENTDVR_VERSION="${AGENTDVR_VERSION//\_/\.}"

# Create a temporary file safely
TEMP_FILE=$(mktemp "${DOCKERFILE_NAME}.XXXXXX") || {
    echo "Error creating temporary file" >&2
    exit 1
}

# Write the Dockerfile content to the temporary file
{
    echo "ARG BASE_IMAGE=$BASE_IMAGE"
    echo "ARG AGENTDVR_VERSION=$AGENTDVR_VERSION"
    echo "FROM $BASE_IMAGE"
    
    # Only add additional content for non-publication builds
    if [ ! -e ./resources/build_data/publication ]; then
        cat << 'EOF'
# Install sudo if not present and clean up
RUN echo 'Acquire::Check-Valid-Until "false";' > /etc/apt/apt.conf.d/99ignore-release-date && \
    apt-get update && \
    (dpkg -l sudo 2>/dev/null | grep -q '^ii' || \
    (echo "sudo is not installed. Installing sudo..." && apt-get install -y sudo)) && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* /etc/apt/apt.conf.d/99ignore-release-date

# Create agentdvr user and set up permissions
RUN useradd -m -d /AgentDVR/ -s /bin/bash -u 1000 agentdvr && \
    echo "agentdvr:agentdvr" | chpasswd && \
    chown -R agentdvr:agentdvr /AgentDVR/ && \
    chmod 775 /AgentDVR/ && \
    mkdir -p /AgentDVR/Commands && \
    chmod -R 777 /AgentDVR/Commands && \
    name="$(whoami)" && \
    echo "Adding permission for USER:root to local device (GPU) access" && \
    usermod -aG video "$name" && \
    echo "Added permission for USER:$name to GPU access" && \
    usermod -aG video agentdvr && \
    echo "Added permission for USER:agentdvr to GPU access" && \
    usermod -aG sudo agentdvr && \
    usermod -aG "$name" agentdvr && \
    usermod -aG agentdvr "$name" && \
    echo "agentdvr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Copy resources and run setup
COPY --chown=agentdvr:agentdvr ./resources /AgentDVR
RUN echo "Running setup script..." && \
    chmod -R 0775 /AgentDVR && \
    bash /AgentDVR/setup.sh && \
    bash /AgentDVR/cleanup.sh && \
    rm -vrf /AgentDVR/cleanup.sh

# Docker needs to run a TURN server to get webrtc traffic to and from it over forwarded ports from the host
# These are the default ports. If the ports below are modified here you'll also need to set the ports in XML/Config.xml
# for example <TurnServerPort>3478</TurnServerPort><TurnServerMinPort>50000</TurnServerMinPort><TurnServerMaxPort>50010</TurnServerMaxPort>
# The main server port is overridden by creating a text file called port.txt in the root directory containing the port number, eg: 8090
# To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.1.12:8090/

# Define default environment variables
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

# Fix a memory leak on encoded recording
ENV MALLOC_TRIM_THRESHOLD_=100000
ENV DOTNET_RUNNING_IN_CONTAINER="true"

# Disable .NET file locking
ENV DOTNET_SYSTEM_IO_DISABLEFILELOCKING=1
ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

# Main UI port
EXPOSE 8090

# HTTPS port
EXPOSE 443

# STUN server port
EXPOSE 3478/udp 3478/tcp

# TURN server UDP port range
EXPOSE 50000-50100/udp

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=5 \
  CMD curl -f http://localhost:${AGENTDVR_WEBUI_PORT:-8090}/ || exit 1

# Define service entrypoint
CMD ["/AgentDVR/Agent.sh"]
EOF
    fi
} > "$TEMP_FILE"

# Atomically replace the target file with the temporary file
if mv -f "$TEMP_FILE" "$DOCKERFILE_NAME"; then
    echo "Dockerfile generation completed!"
    echo "######      DOCKERFILE START     ######"
    cat "$DOCKERFILE_NAME"
    echo "######      DOCKERFILE END     ######"
else
    echo "Error: Failed to create Dockerfile for $REPO_NAME" >&2
    rm -f "$TEMP_FILE"
    exit 1
fi