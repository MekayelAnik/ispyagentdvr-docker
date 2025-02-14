#!/bin/bash
VERSION=$(cat /AgentDVR/build_data/version)
AGENTURL=$(cat /AgentDVR/build_data/binary_server_url)
#########################	UPDATE IMAGE	#########################
# apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
# apt-get full-upgrade -y --no-install-recommends --no-install-suggests
# apt-get autoremove -y
#########################	DO/NOT INSTALL VLC	#########################
if [ -e /AgentDVR/build_data/install-vlc ]; then
	echo "****	Installing VLC	****"
	apt-get install libvlc-dev vlc libx11-dev -y --no-install-recommends --no-install-suggests
	echo "****	Completed Installing VLC	****"
else echo "VLC will not be separately installed here..."
fi

#########################	SETUP COTURN	#########################
setup_coturn() {
    # Define the settings file name
    mkdir -p "/AgentDVR/Media/XML/"
    settings_file="coturn_settings.txt"
    port=3478
    auth_secret="$(tr -dc 'A-Za-z0-9' < /dev/urandom | head -c 16)"

    # Write the entered settings to a text file
    echo "Writing configuration to ${settings_file}..."
    {
        echo "listening_port=${port}"
        echo "auth_secret=${auth_secret}"
        #echo "turn_only=true"
    } > "/AgentDVR/Media/XML/${settings_file}"
    echo "Configuration saved to ${settings_file}"

    apt-get update >> "$LOGFILE" 2>&1 || critical_error "apt-get update failed."
    apt-get install --no-install-recommends -y coturn >> "$LOGFILE" 2>&1 || critical_error "apt-get install failed."

    # Write the new coturn configuration.
    echo "Creating new coturn configuration at ${config_file}..."
    tee "$config_file" > /dev/null <<EOF
# Coturn configuration

# Listen on all available interfaces.
listening-ip=0.0.0.0

# Port on which the TURN server will listen.
listening-port=${port}

realm=agentturn.local

# Define the range of ports used for relayed connections.
min-port=50000
max-port=50100

# Enable long-term credential mechanism.
lt-cred-mech

# Set up static user authentication
static-auth-secret=${auth_secret}

# Enable TURN message integrity and fingerprint.
fingerprint
EOF

    # Enable the coturn service if using the default configuration file.
    default_file="/etc/default/coturn"
    if [ -f "$default_file" ]; then
        echo "Enabling coturn service in ${default_file}..."
        sed -i 's/^\s*#\?\s*TURNSERVER_ENABLED=.*/TURNSERVER_ENABLED=1/' "$default_file"
    fi

    # Restart the coturn service to apply the changes.
    echo "Restarting coturn service..."
    systemctl restart coturn

    echo "coturn has been installed and configured with the following settings:"
    echo "  Listening Port: ${port}"
}

#####	User Permission Setup Starts HERE	#####
arch="$(uname -m)"
name=$(whoami)
echo 'Adding permission for USER:root to local device (GPU) access'
adduser "$name" video
usermod -a -G video "$name"
adduser --gecos GECOS --disabled-password --no-create-home --uid 1000 --ingroup video --shell /bin/bash agentdvr
echo 'Adding permission for agentdvr USER:agentdvr to local device (GPU) access'
usermod -a -G video agentdvr
groupadd --gid 1000 agentdvr
echo 'Adding permission for agentdvr USER:agentdvr to agentdvr Group'
usermod -a -G agentdvr agentdvr
chown -R agentdvr:agentdvr '/AgentDVR'
echo 'Switching to USER:agentdvr'
su agentdvr
cd /AgentDVR
#####	User Permission Setup Ends HERE	#####
echo "Finding iSpy AgentDVR BINARY for $(arch)"
case $(arch) in
	'aarch64' | 'arm64')
		curl --show-error --location "$AGENTURL/Agent_LinuxARM64_$VERSION.zip" -o "AgentDVR.zip"  || DOWNLOAD_ARM64='failed'
		if [ "$DOWNLOAD_ARM64" == 'failed' ]; then
			echo "Agent_LinuxARM64_$VERSION.zip Download FAILED!!! Exiting..." 
			exit 1
		fi
	;;
	'arm' | 'armv6l' | 'armv7l')
      	curl --show-error --location "$AGENTURL/Agent_LinuxARM_$VERSION.zip" -o "AgentDVR.zip"  || DOWNLOAD_ARM='failed'
		if [ "$DOWNLOAD_ARM" == 'failed' ]; then
			echo "Agent_LinuxARM_$VERSION.zip Download FAILED!!! Exiting..." 
			exit 1
		fi
	;;
    'amd64' | 'x86_64')
      	curl --show-error --location "$AGENTURL/Agent_Linux64_$VERSION.zip" -o "AgentDVR.zip"  || DOWNLOAD_AMD64='failed'
		if [ "$DOWNLOAD_AMD64" == 'failed' ]; then
			echo "Agent_Linux64_$VERSION.zip Download FAILED!!! Exiting..." 
			exit 1
		fi
	;;
esac
unzip AgentDVR.zip
rm -vrf AgentDVR.zip
su
setup_coturn
echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
mkdir /agent
ln -sv /AgentDVR/Media /agent/
ln -sv /AgentDVR/Commands /agent/