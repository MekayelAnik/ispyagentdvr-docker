#!/bin/bash
# Standard colors mapped to 8-bit equivalents
ORANGE='\033[38;5;208m'
ERROR_RED='\033[38;5;9m'
LITE_GREEN='\033[38;5;10m'
NAVY_BLUE='\033[38;5;18m'
TANGERINE='\033[38;5;208m'  
GREEN='\033[38;5;2m'
SEA_GREEN='\033[38;5;74m'
ASH_GRAY='\033[38;5;250m'
NC='\033[0m'


# Function to run banner.sh safely and only once
run_banner() {
    if [[ "$__BANNER_EXECUTED" -ne 1 ]]; then
        if [[ -f "$BANNER_FILE" ]]; then
            bash "$BANNER_FILE"
            __BANNER_EXECUTED=1
        else
            printf "${ERROR_RED}Banner file not found: %s${NC}\n" "$BANNER_FILE"
        fi
    fi
}

# Constants and paths
    script_dir=$( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )
    AGENT_DIR="/home/agentdvr/AgentDVR"
    REQUIRED_DIRS=("/home/agentdvr/AgentDVR/Media/XML" "/home/agentdvr/AgentDVR/Media/WebServerRoot/Media" "/home/agentdvr/AgentDVR/Commands" "/home/agentdvr/AgentDVR/Masks" "/home/agentdvr/AgentDVR/sounds") \
    BANNER_FILE="$script_dir/banner.sh"
    AGENT_BINARY="/home/agentdvr/AgentDVR/Agent"
    CONFIG_DIR="/home/agentdvr/AgentDVR/Media/XML"
    COMMANDS_DIR="/home/agentdvr/AgentDVR/Commands"
    SOUNDS_DIR="/home/agentdvr/AgentDVR/sounds"
    MASKS_DIR="/home/agentdvr/AgentDVR/Masks"
    FIRST_RUN="/home/agentdvr/AgentDVR/FirstRun"
    CONTENT_DIR="/home/agentdvr/AgentDVR/Content"
    SESSION_LOG="/home/agentdvr/AgentDVR/Media/sessionlog.txt"

# Error handling function
error_exit() {
    printf "${ERROR_RED}ERROR: %s${NC}\n" "$1" >&2
    exit 1
}

# Move content directories and remove Content folder
migrate_content_directories() {
    if [[ -d "$CONTENT_DIR" ]]; then
        printf "${NAVY_BLUE}Migrating content directories...${NC}\n"
        cp -rf "$CONTENT_DIR/"* "$AGENT_DIR/" || error_exit "Failed to migrate content directories"
        chmod -R 0775 "$COMMANDS_DIR" "$SOUNDS_DIR" "$MASKS_DIR" || error_exit "Failed to set permissions for Commands, Sounds, or Masks directories"
        rm -rf "$CONTENT_DIR" || printf "${ERROR_RED}Warning: Could not completely remove Content directory${NC}\n"
        printf "${LITE_GREEN}Content directories migration completed${NC}\n"
    else
        printf "${ORANGE}No Content directory found, skipping migration.${NC}\n"
    fi
}

# Ensure required directories exist with proper permissions
ensure_directories() {
    # First migrate any content directories with immutable permissions
    migrate_content_directories

    # Fix home directory permissions
    if [[ $(id -u) -eq 0 ]] && [[ -d "/home/agentdvr" ]]; then
        chmod 0775 "/home/agentdvr" || error_exit "Failed to set /home/agentdvr permissions"
    fi

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
            [[ "$dir" == "$COMMANDS_DIR" || "$dir" == "$SOUNDS_DIR" || "$dir" == "$MASKS_DIR" ]] || [[ "$dir" == "$CONFIG_DIR" ]] && continue

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
            chmod 0775 -R "$CONFIG_DIR"||
                error_exit "Failed to set permissions for config directory"
        fi
    fi
    chmod 0775 "$SESSION_LOG"
}


# Permission checking
check_write_permissions() {
    local user="$1" errors=0 dir
    local PC1="${ASH_GRAY}"
    if [[ "$user" == 'agentdvr' ]]; then
        local PC2="${NAVY_BLUE}"
        local PC3="${GREEN}"
    elif [[ "$user" == 'root' ]]; then
        local PC2="${GREEN}"
        local PC3="${ERROR_RED}"
    fi
    printf "${PC1}====================================================================${NC}\n"
    printf "${PC2}Verifying write permissions for user:${NC} ${PC3}%s${NC}\n" "$user"
    printf "${PC1}====================================================================${NC}\n"

    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ -w "$dir" ]]; then
            printf "${GREEN}Checking${NC} ${NAVY_BLUE}%s${NC} ... ${LITE_GREEN}OK${NC}\n" "$dir"
        else
            printf "Checking %s ... ${ERROR_RED}FAILED${NC}\n" "$dir" >&2
            printf "${ERROR_RED}ERROR: User %s cannot write to: %s${NC}\n" "$user" "$dir" >&2
            ((errors++))
        fi
    done

    if (( errors )); then
        error_exit "Required write permissions missing for user: $user"
    fi

    printf "${GREEN}All required permissions verified successfully${NC}\n"
}

run_or_fail() {
    local message="$1"
    shift
    "$@" || error_exit "$message"
}

setup_user_group() {
    # Get current UID/GID of the agentdvr user and group
    current_uid=$(id -u agentdvr 2>/dev/null)
    current_gid=$(id -g agentdvr 2>/dev/null)

    # Only modify UID if PUID is set and different from current
    if [[ -n "$PUID" && "$current_uid" != "$PUID" ]]; then
        run_or_fail "Failed to modify UID for user agentdvr" usermod -u "$PUID" agentdvr
    fi

    # Only modify GID if PGID is set and different from current
    if [[ -n "$PGID" && "$current_gid" != "$PGID" ]]; then
        run_or_fail "Failed to modify GID for group agentdvr" groupmod -g "$PGID" agentdvr
    fi

    # Only change primary group if PGID is set and different from current
    if [[ -n "$PGID" && "$current_gid" != "$PGID" ]]; then
        run_or_fail "Failed to modify primary group for user agentdvr" usermod -g "$PGID" agentdvr
    fi

    if [[ -z "$PGID" && "$current_gid" != "$PUID" ]]; then
        run_or_fail "Failed to modify primary group for user agentdvr" usermod -g "$PUID" agentdvr
    fi
}

# GPU permission setting
set_gpu_permissions() {
    [[ -d /dev/dri ]] || return

    find /dev/dri -name 'renderD*' -type c -print0 2>/dev/null | while IFS= read -r -d '' render_device; do
        if (( $(stat -c '%a' "$render_device") != 0666 )); then
            chmod 0666 "$render_device" ||
                printf "${ERROR_RED}WARNING: Failed to set permissions for %s${NC}\n" "$render_device" >&2
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
run_as_root(){
    check_write_permissions "root"
    exec "$AGENT_BINARY"
}
# Start agent with proper permissions
start_agent() {
    verify_agent_binary
    # Skip user switching if PUID=0 (root)
    if [[ "$PUID" == "0" ]]; then
        printf "${TANGERINE}PUID=0 (root) detected. Running as root.${NC}\n"
        run_as_root
    # Fallback: Run as root (no PUID/PGID set)
    elif [[ -z "$PUID" && -z "$PGID" ]]; then
        printf "${ERROR_RED}Both PUID & PGID are not set. To run as a user, at least you must set the PUID${NC}${TANGERINE}Otherwise, Runing agent as root.${NC}\n"
        run_as_root
    elif [[ -n "$PGID" && -z "$PUID" ]]; then
        printf "${ERROR_RED}PGID is set but PUID is not. Both must be set together or PUID can be set alone.\n${NC} ${ERROR_RED}Please set PUID and PGID togather or only PUID or unset PGID. ${NC}\n${TANGERINE}No PUID/PGID set. Running as root.${NC}\n"
        run_as_root
    elif [[ -n "$PUID" && "$PUID" != "0" ]]; then
        if type -P gosu &>/dev/null; then
            printf "${SEA_GREEN}PUID and PGID are set. Will run as agentdvr user.${NC}\n"
            printf "${SEA_GREEN}Running as agentdvr user:${NC} (${ORANGE}PUID:${NC} ${GREEN}%s${NC} ${ORANGE}PGID:${NC} ${GREEN}%s${NC})\n" "${PUID}" "${PGID:-$PUID}"
            setup_user_group
            check_write_permissions "agentdvr"
            set_gpu_permissions
            exec gosu "${PUID}:${PGID:-$PUID}" "$AGENT_BINARY"
        else
            printf "${ERROR_RED}gosu not found. Running as root instead.${NC}\n"
            run_as_root
        fi
    fi
}

# Main function
main() {
    case "${DEBUG_MODE,,}" in
        yes|ye|y|true|t)
            run_banner
            # Run banner immediately at script start
            if [[ -n "$CUSTOM_ENTRYPOINT" && -x "$CUSTOM_ENTRYPOINT" ]]; then
                chmod +x "$CUSTOM_ENTRYPOINT" || error_exit "Failed to set execute permissions for custom entrypoint"
                printf "${TANGERINE}Running custom entrypoint: %s${NC}\n" "$CUSTOM_ENTRYPOINT"
                printf "${ERROR_RED}Debug mode enabled. Custom entrypoint will be executed.${NC}\n"
                printf "${GREEN}Entering Custom Entry Point in ${NC}"
                for i in 3 2 1; do
                    printf "${NAVY_BLUE}%d ${NC}" "$i"
                    sleep 1
                done
                printf "\r\n"
                export DEBUG_MODE="false"
                export __BANNER_EXECUTED=1
                exec "$CUSTOM_ENTRYPOINT"
            else
                apt-get update && apt-get install nano -y || error_exit "Failed to install nano"
                exec sleep infinity
            fi
            ;;
        *)
            # Run first-time setup only if FirstRun file exists
            run_banner
            if [[ -f "$FIRST_RUN" ]]; then
                ensure_directories
                rm -f "$FIRST_RUN"
            fi
            start_agent
            ;;
    esac
}

main "$@"