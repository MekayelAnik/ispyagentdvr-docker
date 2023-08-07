#!/bin/bash

# Install script for AgentDVR/ Linux
# To execute: save and `chmod +x ./linux_setup2.sh` then `./linux_setup2.sh`
version=4_6_3_0

. /etc/*-release
arch=`uname -m`

ffmpeg_installed=true

if [[ ("$OSTYPE" == "darwin"*) ]]; then
  # If arm64 AND darwin (macOS)
  echo "Use use osx_setup.sh instead"
  exit
fi

machine_has() {
    eval $invocation

    command -v "$1" > /dev/null 2>&1
    return $?
}

ABSOLUTE_PATH="${PWD}"
mkdir AgentDVR
cd AgentDVR


cd $ABSOLUTE_PATH/AgentDVR/
#download latest version

FILE=$ABSOLUTE_PATH/AgentDVR/Agent
if [ ! -f $FILE ]
then
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
else
	echo "Found Agent in $ABSOLUTE_PATH/AgentDVR - delete it to reinstall"
fi

#for backward compat with existing service files

echo "downloading start script for back compat"
curl --show-error --location "https://raw.githubusercontent.com/ispysoftware/agent-install-scripts/main/v2/start_agent.sh" -o "start_agent.sh"
chmod a+x ./start_agent.sh

echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;

cd $ABSOLUTE_PATH

name=$(whoami)
#add permissions for local device access
echo "Adding permission for local device access"
  adduser $name video
  usermod -a -G video $name

	echo "Installing service as $name"
	curl --show-error --location "https://raw.githubusercontent.com/ispysoftware/agent-install-scripts/main/v2/AgentDVR.service" -o "AgentDVR.service"
	sed -i "s|AGENT_LOCATION|$ABSOLUTE_PATH/AgentDVR|" AgentDVR.service
	sed -i "s|YOUR_USERNAME|$name|" AgentDVR.service
	  chmod 644 ./AgentDVR.service

  
	  chown $name -R $ABSOLUTE_PATH/AgentDVR
	  cp AgentDVR.service /etc/systemd/system/AgentDVR.service


exit 0
