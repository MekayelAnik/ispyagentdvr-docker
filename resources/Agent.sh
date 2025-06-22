#!/bin/bash
export DEBUG_MODE='false'
export DOTNET_SYSTEM_IO_DISABLEFILELOCKING=1
ORANGE='\033[0;33m'
WARN_COLOR='\033[1;33m'  # Bold yellow
GREEN_BOLD='\033[1;32m'  # Bright/bold green
BLUE_BRIGHT='\033[1;34m'  # Bold bright blue
COL1='\033[38;5;39m'  # Deep sky blue
COL2='\033[38;5;63m'  # Slate blue
NC='\033[0m'

# Constants and paths
declare -r \
    REQUIRED_DIRS=("/home/agentdvr/AgentDVR/Media/XML" "/home/agentdvr/AgentDVR/Media/WebServerRoot/Media" "/home/agentdvr/AgentDVR/Commands" "/home/agentdvr/AgentDVR/Masks") \
    BANNER_FILE="/home/agentdvr/AgentDVR/banner.sh" \
    AGENT_BINARY="/home/agentdvr/AgentDVR/Agent" \
    CUSTOM_ENTRYPOINT="/home/agentdvr/AgentDVR/Media/XML/customEntrypoint.sh" \
    CONFIG_DIR="/home/agentdvr/AgentDVR/Media/XML" \
    COMMANDS_DIR="/home/agentdvr/AgentDVR/Commands" \
    SESSION_LOG="/home/agentdvr/AgentDVR/Media/sessionlog.txt"
    FIRST_RUN="/home/agentdvr/AgentDVR/FirstRun"

# Error handling function
error_exit() {
    printf '\033[1;31mERROR: %s\033[0m\n' "$1" >&2
    exit 1
}

# Load banner if exists
if [[ -f "$BANNER_FILE" ]]; then
    source "$BANNER_FILE" || :
fi

# Ensure required directories exist with proper permissions
ensure_directories() {
    # Fix home directory permissions first (critical for Docker)
    if [[ $(id -u) -eq 0 ]] && [[ -d "/home/agentdvr" ]]; then
        if [[ $(stat -c '%a' "/home/agentdvr") -ne 775 ]]; then
            chmod 0775 -R "/home/agentdvr" || error_exit "Failed to set /home/agentdvr permissions"
            printf "${GREEN_BOLD}Fixed permissions for /home/agentdvr (now 775)${NC}\n"
        fi
    fi

    # Create session log if it doesn't exist
    if [ ! -f "$SESSION_LOG" ]; then
        touch "$SESSION_LOG" || error_exit "Failed to create session log"
        chown agentdvr:agentdvr "$SESSION_LOG" || error_exit "Failed to set session log ownership"
        chmod 0775 "$SESSION_LOG" || error_exit "Failed to set session log permissions"
        printf "Created session log: %s\n" "$SESSION_LOG"
    fi

    # Special handling for Commands directory
    if [[ ! -d "$COMMANDS_DIR" ]]; then
        mkdir -p "$COMMANDS_DIR" || error_exit "Failed to create Commands directory"
        printf "Created Commands directory: %s\n" "$COMMANDS_DIR"
    fi

    if [[ $(id -u) -eq 0 ]]; then
        chmod -R 0777 "$COMMANDS_DIR" || error_exit "Failed to set Commands directory permissions"
        chown -R agentdvr:agentdvr "$COMMANDS_DIR" || error_exit "Failed to set Commands directory ownership"
    fi

    # Handle other directories
    for dir in "${REQUIRED_DIRS[@]}"; do
        [[ "$dir" == "$COMMANDS_DIR" ]] && continue
        
        if [[ ! -d "$dir" ]]; then
            mkdir -p "$dir" || error_exit "Failed to create directory: $dir"
            printf 'Created directory: %s\n' "$dir"
        fi
        
        if [[ $(id -u) -eq 0 ]]; then
            [[ "$dir" == "$CONFIG_DIR" ]] && continue
            
            find "$dir" -type d ! -perm 0755 -exec chmod 0755 {} + ||
                error_exit "Failed to set directory permissions for: $dir"
            
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
    
    # Special handling for CONFIG_DIR
    if [[ $(id -u) -eq 0 ]]; then
        chown -R agentdvr:agentdvr "$CONFIG_DIR" ||
            error_exit "Failed to set ownership for config directory"
        chmod -R 0775 "$CONFIG_DIR" ||
            error_exit "Failed to set permissions for config directory"
    fi
}

# Validate PUID/PGID
validate_ids() {
    local valid=1
    # Check PUID is either empty or a positive number within range
    if [[ -n "$PUID" ]]; then
        if [[ ! "$PUID" =~ ^[0-9]+$ ]] || (( PUID <= 0 || PUID > 2147483647 )); then
            valid=0
        fi
    fi
    
    # Check PGID is either empty or a positive number within range
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


# Permission checking with proper output handling
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
            stat -c 'Permissions: %A Owner: %U:%G' "$dir" >&2
            ((errors++))
        fi
    done
    
    if (( errors )); then
        error_exit "Required write permissions missing for user: $user"
    fi
    
    printf "${GREEN_BOLD}All required permissions verified successfully${NC}\n"
    printf "${GREEN_BOLD}====================================================================${NC}\n"
}

# User/group setup
setup_user_group() {
    if [[ -n "$PUID" ]] && ! getent passwd "$PUID" &>/dev/null; then
        if ! useradd -u "$PUID" -g "${PGID:-$PUID}" -d /AgentDVR -s /bin/false agentdvr; then
            error_exit "Failed to create user agentdvr"
        fi
    fi
    
    if [[ -n "$PGID" ]] && ! getent group "$PGID" &>/dev/null; then
        if ! groupadd -g "$PGID" agentdvr; then
            error_exit "Failed to create group agentdvr"
        fi
    fi
}

# GPU permission setting
set_gpu_permissions() {
    [[ -d /dev/dri ]] || return
    
    find /dev/dri -name 'renderD*' -type c -print0 2>/dev/null | while IFS= read -r -d '' render_device; do
        if (( $(stat -c '%a' "$render_device") != 0666 )); then
            if ! chmod 0666 "$render_device"; then
                printf '\033[1;33mWARNING: Failed to set permissions for %s\033[0m\n' "$render_device" >&2
            else
                printf "${GREEN_BOLD}====================================================================${NC}\n"
                printf "${GREEN_BOLD}Updated GPU permissions for %s to 0666\n" "$render_device"
                printf "${GREEN_BOLD}====================================================================${NC}\n"
            fi
        fi
    done
}

# Verify Agent binary exists
verify_agent_binary() {
    if [[ ! -f "$AGENT_BINARY" ]]; then
        error_exit "Agent binary not found at $AGENT_BINARY"
    fi
    if [[ ! -x "$AGENT_BINARY" ]]; then
        if ! chmod +x "$AGENT_BINARY"; then
            error_exit "Agent binary is not executable and couldn't set execute permissions"
        fi
    fi
}

# Streamlined agent startup with proper output handling
start_agent() {
    # Ensure required directories exist with proper permissions
    ensure_directories

    
    # If PUID/PGID are set and valid, run as non-root
    if [[ -n "$PUID$PGID" ]] && validate_ids; then
        if type -P gosu &>/dev/null; then

        printf "${BLUE_BRIGHT}====================================================================${NC}\n"
        printf "${BLUE_BRIGHT}Running as agentdvr user (PUID: %s PGID: %s)${NC}\n" "${PUID:-null}" "${PGID:-null}"
        printf "${BLUE_BRIGHT}====================================================================${NC}\n"
            
            setup_user_group
            check_write_permissions "agentdvr"
            set_gpu_permissions
            exec gosu "agentdvr:agentdvr" "$AGENT_BINARY"
        else
            printf '\033[1;31mERROR: gosu not found. Cannot switch user.\033[0m\n' >&2
            printf '\033[1;33mFalling back to direct execution\033[0m\n' >&2
        fi
    fi
    
    # Fallback execution
    printf "${COL1}====================================================================${NC}\n"
    printf "${COL2}Running as current user: %s${NC}\n" "$(id -un)"
    printf "${COL1}====================================================================${NC}\n"
    
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