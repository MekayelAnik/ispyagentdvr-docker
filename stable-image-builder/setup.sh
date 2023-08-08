#!/bin/bash
# Install script PART-1 for AgentDVR/ Linux
# To execute: save and `chmod +x ./linux_setup2.sh` then `./linux_setup2.sh
version=4_9_4_0
. /etc/*-release
arch=`uname -m`
cd /AgentDVR
#download latest version
	echo "finding installer for $(arch)"
	purl="https://ispyfiles.azureedge.net/downloads/Agent_Linux64_"$version".zip"
	case $(arch) in
		'aarch64' | 'arm64')
			purl="https://ispyrtcdata.blob.core.windows.net/downloads/Agent_LinuxARM64_"$version".zip"
		;;
		'arm' | 'armv6l' | 'armv7l')
			purl="https://ispyrtcdata.blob.core.windows.net/downloads/Agent_LinuxARM_"$version".zip"
		;;
	esac

	AGENTURL=$purl
	echo "Downloading $AGENTURL"
	curl --show-error --location "$AGENTURL" -o "AgentDVR.zip"
	unzip AgentDVR.zip
	rm AgentDVR.zip
echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
exit 0
