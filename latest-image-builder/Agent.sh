#!/bin/bash
date +%c > /run-timestamp
cat /AgentDVR/build-timestamp
/AgentDVR/banner.sh
echo "This Container was started on: $(cat /run-timestamp)"

# Check if PUID and PGID have been set. If so, create or modify the user/group.
if [ -n "$PUID" ]; then
  # Check if the user with the given PUID exists
  if id -u $PUID > /dev/null 2>&1; then
    # If the user exists, rename the user to agentdvr
    existing_user=$(getent passwd $PUID | cut -d: -f1)
    echo "User with UID $PUID exists ($existing_user). Renaming to agentdvr."
    usermod -l agentdvr $existing_user
  else
    # If the user does not exist, create a new user with the specified PUID
    echo "Creating new user agentdvr with UID $PUID."
    useradd -u $PUID -m -s /bin/bash agentdvr
  fi
fi

if [ -n "$PGID" ]; then
  # Check if the group with the given PGID exists
  if getent group $PGID > /dev/null; then
    # If the group exists, rename the group to agentdvr
    existing_group=$(getent group $PGID | cut -d: -f1)
    echo "Group with GID $PGID exists ($existing_group). Renaming to agentdvr."
    groupmod -n agentdvr $existing_group
  else
    # If the group does not exist, create a new group with the specified PGID
    echo "Creating new group agentdvr with GID $PGID."
    groupadd -g $PGID agentdvr
  fi
fi

# Check if the user exists
if id "agentdvr" &>/dev/null; then
    # Switch to agentdvr and execute the Agent binary
    chown -R agentdvr:agentdvr '/AgentDVR'
    su -m agentdvr -c '/AgentDVR/Agent'
else
    # run as root if user creation failed (default behavior).
    echo "User agentdvr does not exist. Continuing as $(whoami)..."
    su -m root -c '/AgentDVR/Agent'
fi
