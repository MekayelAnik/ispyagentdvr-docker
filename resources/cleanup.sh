#!/bin/bash
set -euo pipefail

# Configuration
AGENTDVR_DIR="/AgentDVR/"
# NOTE: setup-ffmpeg-linux.sh must NOT be removed. AgentDVR invokes it at
# runtime to unpack an ffmpeg.tar.xz the app downloads when the user enables
# "Software Encoders (FFmpeg GPL)". The script takes a target folder relative
# to /AgentDVR; in Docker that is Media/XML/ffmpeg<version>/, which sits in
# the persisted config volume, so the install survives container recreation.
# Needs tar + xz-utils, which survive this cleanup.
FILES_TO_REMOVE=(
    "setup.sh"
    "agent-register.sh"
    "agent-reset.sh"
    "agent-reset-account.sh"
    "agent-reset-local-login.sh"
    "setup-ffmpeg-osx.sh"
    "agent-uninstall-service.sh"
    "agent-update.sh"
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $*"
}

# Main cleanup function
cleanup() {
    log "Starting system cleanup process..."
    
    # APT cleanup
    log "Removing unnecessary packages..."
    apt-get -y --purge --allow-remove-essential remove unzip wget
    apt-get autoremove -y
    apt-get clean
    
    log "Cleaning package cache..."
    rm -rf /var/lib/apt/lists/*
    rm -rf /var/cache/apt/archives/*
    
    # AgentDVR specific cleanup
    log "Processing AgentDVR directory: $AGENTDVR_DIR"
    if [ -d "$AGENTDVR_DIR" ]; then
        cd "$AGENTDVR_DIR"
        
        # Remove build directory if exists
        if [ -d "build_data" ]; then
            log "Removing build_data directory..."
            rm -rf "build_data"
        fi
        
        # Remove specified files
        log "Removing script files..."
        for file in "${FILES_TO_REMOVE[@]}"; do
            if [ -f "$file" ]; then
                rm -f "$file"
                log "Removed: $file"
            fi
        done
        
        log "AgentDVR cleanup completed successfully."
    else
        log "Warning: AgentDVR directory not found at $AGENTDVR_DIR"
    fi
    
    log "System cleanup finished."
}

# Execute cleanup
cleanup

exit 0