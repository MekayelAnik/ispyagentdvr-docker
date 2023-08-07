#!/bin/bash
# Install script PART-1 for AgentDVR/ Linux
# To execute: save and `chmod +x ./linux_setup2.sh` then `./linux_setup2.sh
. /etc/*-release
arch=`uname -m`
cd /AgentDVR
#download latest version
echo "Finding installer for $(arch)"
	case $(arch) in
		'aarch64' | 'arm64')
			unzip Agent_LinuxArm64_4_7_3_0.zip -d /AgentDVR
		;;
		'arm' | 'armv6l' | 'armv7l')
			unzip Agent_LinuxArm_4_7_3_0.zip -d /AgentDVR
		;;
		'x86_64')
			unzip Agent_Linux64_4_7_3_0.zip -d /AgentDVR
		;;
	esac
	AGENTURL=$(curl -s --fail "$purl" | tr -d '"')
	echo "Downloading $AGENTURL"
	curl --show-error --location "$AGENTURL" -o "AgentDVR.zip"
	unzip AgentDVR.zip
	rm AgentDVR.zip
echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
exit 0