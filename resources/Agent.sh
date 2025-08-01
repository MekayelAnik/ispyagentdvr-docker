#!/bin/bash
# Standard colors mapped to 8-bit equivalents
ORANGE='\033[38;5;208m'
ERROR_RED='\033[38;5;9m'
LITE_GREEN='\033[38;5;10m'
NAVY_BLUE='\033[38;5;18m'
GREEN='\033[38;5;2m'
SEA_GREEN='\033[38;5;74m'
ASH_GRAY='\033[38;5;250m'
BLUE='\033[38;5;12m'
NC='\033[0m'

# Initialize banner execution flag
__BANNER_EXECUTED=0

# Function to run banner.sh safely and only once
run_banner() {
    if [[ "$__BANNER_EXECUTED" -ne 1 ]]; then
        if [[ -f "$BANNER_FILE" ]]; then
            if ! bash "$BANNER_FILE"; then
                printf "${ERROR_RED}Failed to execute banner file: %s${NC}\n" "$BANNER_FILE" >&2
                return 1
            fi
            __BANNER_EXECUTED=1
        else
            printf "${ERROR_RED}Banner file not found: %s${NC}\n" "$BANNER_FILE" >&2
            return 1
        fi
    fi
    return 0
}

# Constants and paths
script_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd -P) || exit 1
AGENT_DIR="/home/agentdvr/AgentDVR"
REQUIRED_DIRS=(
    "/home/agentdvr/AgentDVR/Media/XML"
    "/home/agentdvr/AgentDVR/Media/WebServerRoot/Media"
    "/home/agentdvr/AgentDVR/Commands"
    "/home/agentdvr/AgentDVR/Masks"
    "/home/agentdvr/AgentDVR/sounds"
)
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

# Validate numeric UID/GID
validate_id() {
    local id="$1"
    local type="$2"
    
    if [[ -n "$id" ]]; then
        if ! [[ "$id" =~ ^[0-9]+$ ]]; then
            error_exit "Invalid $type: '$id' - must be numeric"
        fi
        if [[ "$id" -lt 100 ]]; then
            printf "${ORANGE}Warning: $type $id is typically reserved for system accounts${NC}\n" >&2
        fi
    fi
}

# Move content directories and remove Content folder
migrate_content_directories() {
    if [[ -d "$CONTENT_DIR" ]]; then
        printf "${NAVY_BLUE}Migrating content directories...${NC}\n"
        if ! cp -rf "$CONTENT_DIR/"* "$AGENT_DIR/"; then
            error_exit "Failed to migrate content directories"
        fi

        if ! rm -rf "$CONTENT_DIR"; then
            printf "${ERROR_RED}Failed to remove Content directory on first attempt.${NC}\n${LITE_GREEN}Trying Again...${NC}\n"
            sleep 5
            chattr -R -i "$CONTENT_DIR"  # Remove immutable flag
            if ! rm -vrf "$CONTENT_DIR"; then
                 printf "${ERROR_RED}Couldn't remove the Content directory.${NC}\n${ORANGE} Continuing anyways...${NC}\n"
            fi
        fi

    if [[ -n "$PUID" && $PUID -ne 0 ]]; then
        validate_id "$PUID" "PUID"
        validate_id "${PGID:-$PUID}" "PGID"
        
        target_uid="$PUID"
        target_gid="${PGID:-$PUID}"
        dirs=("$COMMANDS_DIR" "$SOUNDS_DIR" "$MASKS_DIR" "$CONFIG_DIR")
        printf "${LITE_GREEN}Changing directory permissions for:\n${NC}"
        for dir_path in "${dirs[@]}"; do
            dir_stats=$(stat -c '%u %g' "$dir_path")
            current_uid=${dir_stats%% *}
            current_gid=${dir_stats#* }
            
            if [[ "$current_uid" != "$target_uid" || "$current_gid" != "$target_gid" ]]; then
                printf "${BLUE}%s\n${NC}" "$dir_path"
                if ! chown -R "$target_uid:$target_gid" "$dir_path"; then
                    printf "${ERROR_RED}Failed to set ownership for: ${NC} ${ORANGE}$dir_path${NC}"
                fi
                if ! chmod 0775 -R "$dir_path"; then
                    printf "${ERROR_RED}Failed to set permissions for: ${NC} ${ORANGE}$dir_path${NC}"
                fi
            fi
        done
    fi
        
        printf "${LITE_GREEN}Content directories migration completed!\n${NC}\n"
    else
        printf "${ORANGE}No Content directory found, skipping migration.${NC}\n"
    fi
}

# Ensure required directories exist with proper permissions
ensure_directories() {
    # First migrate any content directories with immutable permissions
    migrate_content_directories

    # Fix home directory permissions if running as root
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
            if [[ "$dir" == "$COMMANDS_DIR" || "$dir" == "$SOUNDS_DIR" || "$dir" == "$MASKS_DIR" ]] || 
               [[ "$dir" == "$CONFIG_DIR" ]] || [[ "$dir" == "$SESSION_LOG" ]]; then 
                continue
            fi

            if [[ -n "$PUID" && "$PUID" -ne 0 ]]; then
                validate_id "$PUID" "PUID"
                validate_id "$PGID" "PGID"
                
                target_uid="$PUID"
                target_gid="${PGID:-$PUID}"
                current_uid=$(stat -c '%u' "$dir")
                current_gid=$(stat -c '%g' "$dir")

                if [[ "$current_uid" != "$target_uid" || "$current_gid" != "$target_gid" ]]; then
                    if ! chown -R "$target_uid:$target_gid" "$dir"; then
                        error_exit "Failed to change ownership for: $dir"
                    fi
                    if ! chmod 0775 -R "$dir"; then
                        error_exit "Failed to set permissions for directory: $dir"
                    fi
                fi
            fi
        fi
    done
}

# Permission checking
check_write_permissions() {
    local user="$1" errors=0 dir
    
    if [[ "$user" == 'agentdvr' ]]; then
        local PC1="${ASH_GRAY}"
        local PC2="${SEA_GREEN}"
        local PC3="${GREEN}"
    elif [[ "$user" == 'root' ]]; then
        local PC1="${ORANGE}"
        local PC2="${BLUE}"
        local PC3="${ERROR_RED}"
    fi
    
    printf "${PC1}====================================================================${NC}\n"
    printf "${PC2}Verifying write permissions for user:${NC} ${PC3}%s${NC}\n" "$user"
    printf "${PC1}====================================================================${NC}\n"

    for dir in "${REQUIRED_DIRS[@]}"; do
        if [[ -w "$dir" ]]; then
            printf "${GREEN}Checking${NC} ${BLUE}%s${NC} ... ${LITE_GREEN}OK${NC}\n" "$dir"
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
    if ! "$@"; then
        error_exit "$message (Command failed: $*)"
    fi
}

setup_user_group() {
    # Verify agentdvr user exists
    if ! id -u agentdvr >/dev/null 2>&1; then
        error_exit "agentdvr user does not exist"
    fi

    # Get current UID/GID of the agentdvr user and group
    current_uid=$(id -u agentdvr)
    current_gid=$(id -g agentdvr)

    # Only modify UID if PUID is set and different from current
    if [[ -n "$PUID" && "$current_uid" != "$PUID" ]]; then
        validate_id "$PUID" "PUID"
        run_or_fail "Failed to modify UID for user agentdvr" usermod -u "$PUID" agentdvr
    fi

    # Handle group modifications
    if [[ -n "$PGID" ]]; then
        validate_id "$PGID" "PGID"
        
        existing_group=$(getent group "$PGID" | cut -d: -f1)
        
        # If the target GID already exists
        if [[ -n "$existing_group" ]]; then
            printf "${ORANGE}Group with GID %s already exists (%s). Using existing group.${NC}\n" "$PGID" "$existing_group"
            
            # Delete agentdvr group if it exists and isn't the existing group
            if [[ "$existing_group" != "agentdvr" ]] && getent group agentdvr >/dev/null; then
                # Add agentdvr user to the existing group and make it primary
                if ! usermod -aG "$PGID" agentdvr || ! usermod -g "$PGID" agentdvr; then
                    error_exit "Failed to modify group membership for agentdvr"
                fi
                groupdel agentdvr || printf "${ORANGE}Warning: Could not delete agentdvr group${NC}\n"
            fi
        else
            # If the GID doesn't exist, modify the agentdvr group
            run_or_fail "Failed to modify GID for group agentdvr" groupmod -g "$PGID" agentdvr
        fi
    elif [[ -z "$PGID" && "$current_gid" != "$PUID" ]]; then
        # Default case when only PUID is set
        run_or_fail "Failed to modify primary group for user agentdvr" usermod -g "$PUID" agentdvr
    fi
}

# GPU permission setting
set_gpu_permissions() {
    [[ -d /dev/dri ]] || return 0

    find /dev/dri -name 'renderD*' -type c -print0 2>/dev/null | while IFS= read -r -d '' render_device; do
        if [[ $(stat -c '%a' "$render_device") != 666 ]]; then
            if ! chmod 0666 "$render_device"; then
                printf "${ERROR_RED}WARNING: Failed to set permissions for %s${NC}\n" "$render_device" >&2
                return 1
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
        chmod +x "$AGENT_BINARY" || error_exit "Agent binary is not executable and couldn't set execute permissions"
    fi
}

run_as_root() {
    check_write_permissions "root"
    exec "$AGENT_BINARY"
}

# Start agent with proper permissions
start_agent() {
    verify_agent_binary
    
    # Skip user switching if PUID=0 (root)
    if [[ "$PUID" == "0" ]]; then
        printf "${ORANGE}PUID=0 (root) detected. Running as root.${NC}\n"
        run_as_root
    # Fallback: Run as root (no PUID/PGID set)
    elif [[ -z "$PUID" && -z "$PGID" ]]; then
        printf "${ERROR_RED}Both PUID & PGID are not set. To run as a user, at least you must set the PUID${NC}\n"
        printf "${ORANGE}Running agent as root.${NC}\n"
        run_as_root
    elif [[ -n "$PGID" && -z "$PUID" ]]; then
        printf "${ERROR_RED}PGID is set but PUID is not. Both must be set together or PUID can be set alone.${NC}\n"
        printf "${ERROR_RED}Please set PUID and PGID together or only PUID or unset PGID.${NC}\n"
        printf "${ORANGE}No PUID/PGID set. Running as root.${NC}\n"
        run_as_root
    elif [[ -n "$PUID" && "$PUID" -ne 0 ]]; then
        if type -P gosu &>/dev/null; then
            printf "${SEA_GREEN}PUID and PGID are set. Will run as agentdvr user.${NC}\n"
            printf "${SEA_GREEN}Running as agentdvr user:${NC} (${ORANGE}PUID:${NC} ${GREEN}%s${NC} ${ORANGE}PGID:${NC} ${GREEN}%s${NC})\n" "${PUID}" "${PGID:-$PUID}"
            
            # Setup user/group before checking permissions
            setup_user_group
            set_gpu_permissions
            check_write_permissions "agentdvr"
            
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
            # Run banner immediately at script start
            if [[ -n "$CUSTOM_ENTRYPOINT" && -x "$CUSTOM_ENTRYPOINT" ]]; then
                chmod +x "$CUSTOM_ENTRYPOINT" || error_exit "Failed to set execute permissions for custom entrypoint"
                printf "${ORANGE}Running custom entrypoint: %s${NC}\n" "$CUSTOM_ENTRYPOINT"
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
                apt-get update && apt-get install -y --no-install-recommends nano || error_exit "Failed to install nano"
                exec sleep infinity
            fi
            ;;
        *)
            if ! run_banner; then
                printf "${ORANGE}Continuing despite banner execution failure${NC}\n"
            fi
            
            # Run first-time setup only if FirstRun file exists
            if [[ -f "$FIRST_RUN" ]]; then
                printf "${ORANGE}\nNOTE: Booting container for the first time... \nIt may take some time. Please wait...\n\n${NC}"
                ensure_directories
                rm -f "$FIRST_RUN" || error_exit "Failed to remove FirstRun file"
            fi
            
            start_agent
            ;;
    esac
}

main "$@"