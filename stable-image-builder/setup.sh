#!/bin/bash
# Install script PART-1 for AgentDVR/ Linux
# To execute: save and `chmod +x ./linux_setup2.sh` then `./linux_setup2.sh
version=4_7_6_0
. /etc/*-release
arch=`uname -m`
cd /AgentDVR
#download latest version
echo "Finding installer for $(arch)"
	echo "finding installer for $(arch)"
	purl="https://ispyfiles.azureedge.net/downloads/Agent_Linux64_"$version".zip"
	
	case $(arch) in
		'aarch64' | 'arm64')
			purl="https://ispyfiles.azureedge.net/downloads/Agent_LinuxARM64_"$version".zip"
		;;
		'arm' | 'armv6l' | 'armv7l')
			{
			armhfDep=1
			purl="https://ispyfiles.azureedge.net/downloads/Agent_LinuxArm_$version.zip"
			}
		;;
	if [[ $armhfDep == 1 ]];
 then 	{
		apt-get install -y libatlas-base-dev libatlas3-base  --no-install-recommends
		apt-get -t experimental install -y glibc-source
	}
	fi
	AGENTURL=$purl
	echo "Downloading $AGENTURL"
	curl --show-error --location "$AGENTURL" -o "AgentDVR.zip"
	unzip AgentDVR.zip
	rm AgentDVR.zip
echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
exit 0


apt-get update