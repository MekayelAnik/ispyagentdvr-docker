#!/bin/bash
export DEBUG_MODE='false'
export DOTNET_SYSTEM_IO_DISABLEFILELOCKING=1
ORANGE='\033[0;33m'
WARN_COLOR='\033[1;33m'
GREEN_BOLD='\033[1;32m'
BLUE_BRIGHT='\033[1;34m'
COL1='\033[38;5;63m'
NC='\033[0m'

# Constants and paths
declare -r \
    REQUIRED_DIRS=("/home/agentdvr/AgentDVR/Media/XML" "/home/agentdvr/AgentDVR/Media/WebServerRoot/Media" "/home/agentdvr/AgentDVR/Commands" "/home/agentdvr/AgentDVR/Masks" "/home/agentdvr/AgentDVR/sounds") \
    BANNER_FILE="/home/agentdvr/AgentDVR/banner.sh" \
    AGENT_BINARY="/home/agentdvr/AgentDVR/Agent" \
    CUSTOM_ENTRYPOINT="/home/agentdvr/AgentDVR/Media/XML/customEntrypoint.sh" \
    CONFIG_DIR="/home/agentdvr/AgentDVR/Media/XML" \
    COMMANDS_DIR="/home/agentdvr/AgentDVR/Commands" \
    SOUNDS_DIR="/home/agentdvr/AgentDVR/sounds" \
    MASKS_DIR="/home/agentdvr/AgentDVR/Masks" \
    SESSION_LOG="/home/agentdvr/AgentDVR/Media/sessionlog.txt" \
    FIRST_RUN="/home/agentdvr/AgentDVR/FirstRun" \
    CONTENT_DIR="/home/agentdvr/AgentDVR/Content"

# Error handling function
error_exit() {
    printf '\033[1;31mERROR: %s\033[0m\n' "$1" >&2
    exit 1
}

# Load banner if exists
if [[ -f "$BANNER_FILE" ]]; then
    source "$BANNER_FILE" || :
fi

# Function to set immutable permissions and ownership
set_immutable_permissions() {
    local target="$1"
    local perm="$2"
    local owner="${3:-agentdvr:agentdvr}"
    
    # Set ownership first
    chown "$owner" "$target" || return 1
    
    # Set the permissions
    chmod "$perm" "$target" || return 1
    
    # Make immutable if possible
    if command -v chattr &>/dev/null; then
        chattr +i "$target" 2>/dev/null
    fi
    
    return 0
}

# Move content directories and remove Content folder
migrate_content_directories() {
    if [[ -d "$CONTENT_DIR" ]]; then
        printf "${BLUE_BRIGHT}Migrating content directories...${NC}\n"
        
        # Move Commands directory with immutable 0777 permissions
        if [[ -d "${CONTENT_DIR}/Commands" ]]; then
            printf "Moving Commands directory with 0777 permissions...\n"
            if [[ -d "$COMMANDS_DIR" ]]; then
                cp -rn "${CONTENT_DIR}/Commands/"* "$COMMANDS_DIR/" || printf "${WARN_COLOR}Warning: Some files could not be copied to Commands directory${NC}\n"
            else
                mv "${CONTENT_DIR}/Commands" "$COMMANDS_DIR" || error_exit "Failed to move Commands directory"
            fi
            set_immutable_permissions "$COMMANDS_DIR" "0777" || error_exit "Failed to set immutable permissions for Commands directory"
        fi
        
        # Move sounds directory with immutable 0775 permissions
        if [[ -d "${CONTENT_DIR}/sounds" ]]; then
            printf "Moving sounds directory with 0775 permissions...\n"
            if [[ -d "$SOUNDS_DIR" ]]; then
                cp -rn "${CONTENT_DIR}/sounds/"* "$SOUNDS_DIR/" || printf "${WARN_COLOR}Warning: Some sound files could not be copied${NC}\n"
            else
                mv "${CONTENT_DIR}/sounds" "$SOUNDS_DIR" || error_exit "Failed to move sounds directory"
            fi
            set_immutable_permissions "$SOUNDS_DIR" "0775" || error_exit "Failed to set immutable permissions for sounds directory"
        fi
        
        # Move Masks directory with immutable 0775 permissions
        if [[ -d "${CONTENT_DIR}/Masks" ]]; then
            printf "Moving Masks directory with 0775 permissions...\n"
            if [[ -d "$MASKS_DIR" ]]; then
                cp -rn "${CONTENT_DIR}/Masks/"* "$MASKS_DIR/" || printf "${WARN_COLOR}Warning: Some mask files could not be copied${NC}\n"
            else
                mv "${CONTENT_DIR}/Masks" "$MASKS_DIR" || error_exit "Failed to move Masks directory"
            fi
            set_immutable_permissions "$MASKS_DIR" "0775" || error_exit "Failed to set immutable permissions for Masks directory"
        fi
        
        # Remove Content directory after migration
        printf "Removing Content directory...\n"
        rm -rf "$CONTENT_DIR" || printf "${WARN_COLOR}Warning: Could not completely remove Content directory${NC}\n"
        
        printf "${GREEN_BOLD}Content directories migration completed${NC}\n"
    fi
}

# Ensure required directories exist with proper permissions
ensure_directories() {
    # First migrate any content directories with immutable permissions
    migrate_content_directories
    
    # Fix home directory permissions
    if [[ $(id -u) -eq 0 ]] && [[ -d "/home/agentdvr" ]]; then
        chmod 0755 "/home/agentdvr" || error_exit "Failed to set /home/agentdvr permissions"
    fi

    # Create and protect session log file
    if [ ! -f "$SESSION_LOG" ]; then
        touch "$SESSION_LOG" || error_exit "Failed to create session log"
    fi
    set_immutable_permissions "$SESSION_LOG" "0777" || error_exit "Failed to set immutable permissions for session log"

    # Handle all declared directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        # Skip if immutable permissions already set
        if [[ -e "$dir" ]] && [[ $(lsattr -d "$dir" 2>/dev/null | cut -c5) == "i" ]]; then
            continue
        fi
        
        # Create directory if it doesn't exist
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || error_exit "Failed to create directory: $dir"
        fi
        
        # Set permissions if running as root
        if [[ $(id -u) -eq 0 ]]; then
            # Skip if this is a special directory (handled during migration)
            [[ "$dir" == "$COMMANDS_DIR" || "$dir" == "$SOUNDS_DIR" || "$dir" == "$MASKS_DIR" ]] && continue
            
            # Skip permission setting for CONFIG_DIR (handled separately)
            [[ "$dir" == "$CONFIG_DIR" ]] && continue
            
            # Default permissions for directories (0755)
            find "$dir" -type d ! -perm 0755 -exec chmod 0755 {} + ||
                error_exit "Failed to set directory permissions for: $dir"
            
            # Default permissions for files (0644)
            find "$dir" -type f ! -perm 0644 -exec chmod 0644 {} + ||
                error_exit "Failed to set file permissions for: $dir"
            
            if [[ -n "$PUID" ]]; then
                target_uid="$PUID"
                target_gid="${PGID:-$PUID}"
                current_uid=$(stat -c '%u' "$dir")
                current_gid=$(stat -c '%g' "$dir")
                
                if [[ "$current_uid" != "$target_uid" || "$current_gid" != "$target_gid" ]]; then
                    chown -R "$target_uid:$target_gid" "$dir" ||
                        error_exit "Failed to change ownership for: $dir"
                fi
            fi
        fi
    done
    
    # Special handling for CONFIG_DIR with immutable permissions
    if [[ $(id -u) -eq 0 ]]; then
        if [[ ! -e "$CONFIG_DIR" ]] || [[ $(lsattr -d "$CONFIG_DIR" 2>/dev/null | cut -c5) != "i" ]]; then
            chown -R agentdvr:agentdvr "$CONFIG_DIR" ||
                error_exit "Failed to set ownership for config directory"
            set_immutable_permissions "$CONFIG_DIR" "0775" ||
                error_exit "Failed to set immutable permissions for config directory"
        fi
    fi
}

# Validate PUID/PGID
validate_ids() {
    local valid=1
    if [[ -n "$PUID" ]]; then
        if [[ ! "$PUID" =~ ^[0-9]+$ ]] || (( PUID <= 0 || PUID > 2147483647 )); then
            valid=0
        fi
    fi
    
    if [[ -n "$PGID" ]]; then
        if [[ ! "$PGID" =~ ^[0-9]+$ ]] || (( PGID <= 0 || PGID > 2147483647 )); then
            valid=0
        fi
    fi
    
    if (( ! valid )); then
        error_exit "${WARN_COLOR}Invalid ID(s) PUID=${PUID:-null} PGID=${PGID:-null} - must be numeric, greater than 0 and less than or equal to 2147483647${NC}\n"
    fi
    return 0
}

# Permission checking
check_write_permissions() {
    local user="$1" errors=0 dir

    printf "${ORANGE}====================================================================${NC}\n"
    printf "${ORANGE}Verifying write permissions for user: %s${NC}\n" "$user"
    printf "${ORANGE}====================================================================${NC}\n"
    
    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ -w "$dir" ]]; then
            printf 'Checking %s ... \033[1;32mOK\033[0m\n' "$dir"
        else
            printf 'Checking %s ... \033[1;31mFAILED\033[0m\n' "$dir" >&2
            printf '\033[1;31mERROR: User %s cannot write to: %s\033[0m\n' "$user" "$dir" >&2
            ((errors++))
        fi
    done
    
    if (( errors )); then
        error_exit "Required write permissions missing for user: $user"
    fi
    
    printf "${GREEN_BOLD}All required permissions verified successfully${NC}\n"
}

# User/group setup
setup_user_group() {
    if [[ -n "$PUID" ]] && ! getent passwd "$PUID" &>/dev/null; then
        useradd -u "$PUID" -g "${PGID:-$PUID}" -d /AgentDVR -s /bin/false agentdvr ||
            error_exit "Failed to create user agentdvr"
    fi
    
    if [[ -n "$PGID" ]] && ! getent group "$PGID" &>/dev/null; then
        groupadd -g "$PGID" agentdvr ||
            error_exit "Failed to create group agentdvr"
    fi
}

# GPU permission setting
set_gpu_permissions() {
    [[ -d /dev/dri ]] || return
    
    find /dev/dri -name 'renderD*' -type c -print0 2>/dev/null | while IFS= read -r -d '' render_device; do
        if (( $(stat -c '%a' "$render_device") != 0666 )); then
            chmod 0666 "$render_device" || 
                printf '\033[1;33mWARNING: Failed to set permissions for %s\033[0m\n' "$render_device" >&2
        fi
    done
}

# Verify Agent binary exists
verify_agent_binary() {
    if [[ ! -f "$AGENT_BINARY" ]]; then
        error_exit "Agent binary not found at $AGENT_BINARY"
    fi
    if [[ ! -x "$AGENT_BINARY" ]]; then
        chmod +x "$AGENT_BINARY" ||
            error_exit "Agent binary is not executable and couldn't set execute permissions"
    fi
}

# Start agent with proper permissions
start_agent() {
    ensure_directories

    if [[ -n "$PUID$PGID" ]] && validate_ids; then
        if type -P gosu &>/dev/null; then
            printf "${BLUE_BRIGHT}Running as agentdvr user (PUID: %s PGID: %s)${NC}\n" "${PUID:-null}" "${PGID:-null}"
            setup_user_group
            check_write_permissions "agentdvr"
            set_gpu_permissions
            exec gosu "agentdvr:agentdvr" "$AGENT_BINARY"
        else
            printf '\033[1;31mERROR: gosu not found. Cannot switch user.\033[0m\n' >&2
        fi
    fi
    
    # Fallback execution
    printf "${COL1}Running as current user: %s${NC}\n" "$(id -un)"
    check_write_permissions "$(id -un)"
    exec "$AGENT_BINARY"
}

# Main function
main() {
    [[ -f "$FIRST_RUN" ]] && { rm -f "$FIRST_RUN"; exec timeout -k 5 5 "$AGENT_BINARY"; }
    
    case "${DEBUG_MODE,,}" in
        yes|ye|y|true|t)
            if [[ -x "$CUSTOM_ENTRYPOINT" ]]; then
                exec "$CUSTOM_ENTRYPOINT"
            else
                exec sleep infinity
            fi
            ;;
        *)  start_agent ;;
    esac
}

main "$@"