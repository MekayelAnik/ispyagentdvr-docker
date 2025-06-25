#!/bin/bash
set -euo pipefail  # Exit on error, undefined variables, and pipe failures

# Configuration
declare -r \
AGENT_DIR="/home/agentdvr/AgentDVR" \
SESSION_LOG="/home/agentdvr/AgentDVR/Media/sessionlog.txt"

AGENT_UID=${AGENT_UID:-1000}
AGENT_GID=${AGENT_GID:-1000}

######################### INITIAL CHECKS #########################

# Verify sudo privileges early
if [ "$(id -u)" -ne 0 ] && ! sudo -n true 2>/dev/null; then
    echo "Error: This script requires root/sudo privileges"
    exit 1
fi

# Check and install required dependencies
REQUIRED_CMDS="curl unzip"
for cmd in $REQUIRED_CMDS; do
    if ! command -v "$cmd" >/dev/null 2>&1; then
        echo "Installing missing dependency: $cmd"
        apt-get update && apt-get install -y "$cmd"
    fi
done

# Verify AGENT_DIR directory exists
mkdir -p "$AGENT_DIR/build_data" || { echo "Failed to create $AGENT_DIR/build_data"; exit 1; }

# Check for required files explicitly
if [ ! -f "$AGENT_DIR/build_data/version" ] || [ ! -f "$AGENT_DIR/build_data/binary_server_url" ]; then
    echo "Error: Missing required files in $AGENT_DIR/build_data"
    exit 1
fi

VERSION=$(cat "$AGENT_DIR/build_data/version")
AGENTURL=$(cat "$AGENT_DIR/build_data/binary_server_url")

# Cleanup function
cleanup() {
    # Remove temporary files if they exist
    [ -f "$AGENT_DIR/AgentDVR.zip" ] && rm -f "$AGENT_DIR/AgentDVR.zip"
    echo "Cleanup complete"
}

trap cleanup EXIT INT TERM

######################### USER PERMISSION SETUP #########################
echo "Setting up users and permissions..."

# Create agentdvr group if it doesn't exist
if ! getent group agentdvr >/dev/null; then
    groupadd --gid "$AGENT_GID" agentdvr || { echo "Failed to create group"; exit 1; }
fi

# Create agentdvr user if it doesn't exist
if ! id -u agentdvr >/dev/null 2>&1; then
    adduser --gecos '' --disabled-password --no-create-home \
            --uid "$AGENT_UID" --ingroup agentdvr --shell /bin/false agentdvr \
            || { echo "Failed to create user"; exit 1; }
fi

# Add users to video group
for user in root $(whoami) agentdvr; do
    if ! id -nG "$user" | grep -qw video; then
        echo "Adding $user to video group"
        usermod -a -G video "$user" || { echo "Failed to add $user to video group"; continue; }
    fi
done

# Set ownership of AgentDVR directory
echo "Setting ownership of $AGENT_DIR"
mkdir -p "$AGENT_DIR"
chown -R agentdvr:agentdvr "$AGENT_DIR" || { echo "Failed to set ownership"; exit 1; }
cd "$AGENT_DIR" || { echo "Failed to change directory"; exit 1; }

######################### UPDATE IMAGE #########################
if [ -f "$AGENT_DIR/build_data/update_base_image" ]; then
    echo "**** Updating system packages (update_base_image flag present) ****"
    apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
    apt-get full-upgrade -y --no-install-recommends --no-install-suggests
    apt-get autoremove -y
else
    echo "Skipping system updates (update_base_image flag not present)"
fi

######################### INSTALL VLC (CONDITIONAL) #########################
if [ -f "$AGENT_DIR/build_data/install-vlc" ]; then
    echo "**** Installing VLC ****"
    apt-get install libvlc-dev vlc libx11-dev -y --no-install-recommends --no-install-suggests
    echo "**** Completed Installing VLC ****"
else 
    echo "VLC will not be separately installed here..."
fi

######################### DOWNLOAD AND INSTALL AGENT #########################
echo "Finding iSpy AgentDVR BINARY for $(arch)"

# Download appropriate binary
case $(arch) in
    'aarch64' | 'arm64')
        binary="Agent_LinuxARM64_$VERSION.zip"
        ;;
    'arm' | 'armv6l' | 'armv7l')
        binary="Agent_LinuxARM_$VERSION.zip"
        ;;
    'amd64' | 'x86_64')
        binary="Agent_Linux64_$VERSION.zip"
        ;;
    *)
        echo "Unsupported architecture: $(arch)"
        exit 1
        ;;
esac

echo "Downloading $binary" from "$AGENTURL"
HTTP_STATUS=$(curl -s -o /dev/null -w "%{http_code}" "$AGENTURL/$binary")

if [[ "$HTTP_STATUS" == 2* ]]; then
    echo "File Found Online! HTTP Status: $HTTP_STATUS"
elif [[ "$HTTP_STATUS" == 404 ]]; then
    echo "Error: File not found (404)"
else
    echo "Unexpected HTTP status: $HTTP_STATUS"
fi

if ! sudo -u agentdvr curl --show-error --location "$AGENTURL/$binary" -o "AgentDVR.zip"; then
    echo "$binary Download FAILED!!! Exiting..." 
    exit 1
fi
# Checksum verification if available
if [ -f "$AGENT_DIR/build_data/checksum" ]; then
    echo "Verifying checksum..."
    if ! sha256sum -c "$AGENT_DIR/build_data/checksum"; then
        echo "Checksum verification failed!"
        exit 1
    fi
fi

echo "Unzipping AgentDVR"
if ! sudo -u agentdvr unzip AgentDVR.zip; then
    echo "Failed to unzip AgentDVR.zip"
    exit 1
else 
    echo "Unzipped AgentDVR.zip successfully!"
fi

######################### FINAL SETUP #########################
echo "Configuring final permissions and links"

# Set execute permissions
sudo -u agentdvr chmod +x ./Agent || { echo "Failed to set execute permissions"; exit 1; }
sudo -u agentdvr find . -name "*.sh" -exec chmod +x {} \; || { echo "Failed to set script permissions"; exit 1; }

# Create and link directories
for dir in /agent /AgentDVR; do
    if [ -e "$dir" ] && [ ! -d "$dir" ]; then
        echo "Error: $dir exists but is not a directory"
        exit 1
    fi
    mkdir -p "$dir" || { echo "Failed to create $dir"; exit 1; }
    chown agentdvr:agentdvr "$dir" || { echo "Failed to set permissions for $dir"; exit 1; }
done

if [ ! -d "$AGENT_DIR/Media" ]; then
    echo "Creating directory: $AGENT_DIR/Media"
    mkdir -p "$AGENT_DIR/Media" || { echo "Failed to create Media directory"; exit 1; }
fi
if [ ! -d "$AGENT_DIR/Commands" ]; then
    echo "Creating directory: $AGENT_DIR/Commands"
    mkdir -p "$AGENT_DIR/Commands" || { echo "Failed to create Commands directory"; exit 1; }
fi
if [ ! -d "$AGENT_DIR/sounds" ]; then
    echo "Creating directory: $AGENT_DIR/sounds"
    mkdir -p "$AGENT_DIR/sounds" || { echo "Failed to create sounds directory"; exit 1; }
fi
if [ ! -d "$AGENT_DIR/Masks" ]; then
    echo "Creating directory: $AGENT_DIR/Masks"
    mkdir -p "$AGENT_DIR/Masks" || { echo "Failed to create Masks directory"; exit 1; }
fi

if [ ! -f "$SESSION_LOG" ]; then
    echo "Creating Session log: $SESSION_LOG"
    touch "$SESSION_LOG" || { echo "Failed to session log"; exit 1; }
fi

# Create FirstRun file
sudo -u agentdvr touch "$AGENT_DIR/FirstRun" || { echo "Failed to create FirstRun file"; exit 1; }

if ! chmod 0775 -R "$AGENT_DIR"; then
    error_exit "Failed to set permissions for directory: $AGENT_DIR"
fi

if ! chown agentdvr:agentdvr -R "$AGENT_DIR"; then
    error_exit "Failed to change ownership for directory: $AGENT_DIR"
fi

sudo -u agentdvr ln -sfv "$AGENT_DIR/Media" /agent/ || { echo "Failed to create Media link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/Commands" /agent/ || { echo "Failed to create Commands link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/Masks" /agent/ || { echo "Failed to create Media link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/sounds" /agent/ || { echo "Failed to create Commands link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/Media" /AgentDVR/ || { echo "Failed to create Media link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/Commands" /AgentDVR/ || { echo "Failed to create Commands link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/Masks" /AgentDVR/ || { echo "Failed to create Media link"; exit 1; }
sudo -u agentdvr ln -sfv "$AGENT_DIR/sounds" /AgentDVR/ || { echo "Failed to create Commands link"; exit 1; }



echo "Agent DVR setup completed successfully"
