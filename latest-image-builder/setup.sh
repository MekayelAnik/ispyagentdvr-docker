#!/bin/bash
. /etc/*-release
arch=`uname -m`
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
#download latest version
	echo "Finding installer for $(arch)"
	purl="https://www.ispyconnect.com/api/Agent/DownloadLocation4?platform=Linux64&fromVersion=0"
	
	case $(arch) in
		'aarch64' | 'arm64')
			purl="https://www.ispyconnect.com/api/Agent/DownloadLocation4?platform=LinuxARM64&fromVersion=0"
		;;
		'arm' | 'armv6l' | 'armv7l')
      			purl="https://www.ispyconnect.com/api/Agent/DownloadLocation4?platform=LinuxARM&fromVersion=0"
		;;
	esac

	AGENTURL=$(curl -s --fail "$purl" | tr -d '"')
	echo "Downloading $AGENTURL"
	curl --show-error --location "$AGENTURL" -o "AgentDVR.zip"
	unzip AgentDVR.zip
	rm AgentDVR.zip
 	su
echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
exit 0
