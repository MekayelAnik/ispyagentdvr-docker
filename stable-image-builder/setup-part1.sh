#!/bin/bash
# Install script PART-1 for AgentDVR/ Linux
# To execute: save and `chmod +x ./linux_setup2.sh` then `./linux_setup2.sh`
version=4_7_2_0
. /etc/*-release
arch=`uname -m`
machine_has() {
    eval $invocation

    command -v "$1" > /dev/null 2>&1
    return $?
}
mkdir AgentDVR
cd /AgentDVR
#download latest version
	echo "finding installer for $(arch)"
	purl="https://ispyfiles.azureedge.net/downloads/Agent_Linux64_"$version".zip"
	
	case $(arch) in
		'aarch64' | 'arm64')
			purl="https://ispyfiles.azureedge.net/downloads/Agent_LinuxARM64_"$version".zip"
		;;
		'arm' | 'armv6l' | 'armv7l')
			purl="https://ispyfiles.azureedge.net/downloads/Agent_LinuxARM_"$version".zip"
		;;
	esac
	AGENTURL=$purl
	echo "Downloading $AGENTURL"
	curl --show-error --location "$AGENTURL" -o "AgentDVR.zip"
	unzip AgentDVR.zip
	rm AgentDVR.zip

#for backward compat with existing service files
echo "downloading start script for back compat"
curl --show-error --location "https://raw.githubusercontent.com/ispysoftware/agent-install-scripts/main/v2/start_agent.sh" -o "start_agent.sh"
chmod a+x ./start_agent.sh

echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
exit 0
