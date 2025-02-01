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
				echo "Agent_LinuxARM64_$VERSION.zip Download FAILED!!! Exitting..." 
				exit 1
			fi
		;;
		'arm' | 'armv6l' | 'armv7l')
      		curl --show-error --location "$AGENTURL/Agent_LinuxARM_$VERSION.zip" -o "AgentDVR.zip"  || DOWNLOAD_ARM='failed'
			if [ "$DOWNLOAD_ARM" == 'failed' ]; then
				echo "Agent_LinuxARM_$VERSION.zip Download FAILED!!! Exitting..." 
				exit 1
			fi
		;;
        'amd64' | 'x86_64')
      		curl --show-error --location "$AGENTURL/Agent_Linux64_$VERSION.zip" -o "AgentDVR.zip"  || DOWNLOAD_AMD64='failed'
			if [ "$DOWNLOAD_AMD64" == 'failed' ]; then
				echo "Agent_Linux64_$VERSION.zip Download FAILED!!! Exitting..." 
				exit 1
			fi
		;;
	esac
	unzip AgentDVR.zip
	rm -vrf AgentDVR.zip
 	su
echo "Adding execute permissions"
chmod +x ./Agent
find . -name "*.sh" -exec chmod +x {} \;
mkdir /agent
ln -sv /AgentDVR/Media /agent/
ln -sv /AgentDVR/Commands /agent/