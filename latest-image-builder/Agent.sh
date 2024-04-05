#!/bin/bash
start_agent() {
###### Special Thanks to "Dylan Como" (https://github.com/Orange-418) for the Help in the "Run Docker Container as a Spesific user/group section".	######
# Check if PUID and PGID have been set. If so, create or modify the user/group.
if [ -n "$PUID" ]; then 
	if [[ "$PUID" =~ ^[0-9]+$ ]]; then
		if [[ "$PUID" -ge 1000 ]] && [[ "$PUID" -le 2147483647 ]]; then
			usermod -u "$PUID" agentdvr
			UID_CHANGED='true'
		else
			echo "The vlaue of PUID is $PUID which is NOT in Valid Range (Greater than or Equal to 1000 & Less than or Equal to 2147483647). Running AgentDVR as $(whoami)..."
		fi
	else
		echo "The vlaue of PUID is $PUID which is NOT Numeric. Running AgentDVR as $(whoami)..."
	fi
fi
if [ -n "$PGID" ]; then
	if [[ "$PGID" =~ ^[0-9]+$ ]]; then
		if [[ "$PGID" -ge 1000 ]] && [[ "$PGID" -le 2147483647 ]]; then
			groupmod -g "$PGID" agentdvr
			usermod -a -G agentdvr agentdvr
			GID_CHANGED='true'
		else
			echo "The vlaue of PGID is $PGID which is NOT in Valid Range (Greater than or Equal to 1000 & Less than or Equal to 2147483647). Running AgentDVR as $(whoami)..."
		fi
	else
		echo "The vlaue of PGID is $PGID which is NOT Numeric. Running AgentDVR as $(whoami)..."
	fi
fi
if [[ "$UID_CHANGED" == 'true' ]] && [[ "$GID_CHANGED" == 'true' ]]; then
	#####	Add Permission to Use GPU Encode/Decode by Users other than root	##### 
	for ((i = 128; i <= 150; i++)); do
		if [ -e /dev/dri/renderD"$i" ]; then
        		chmod 0666 /dev/dri/renderD"$i"
    	fi
	done
    # Switch to agentdvr and execute the Agent binary
    chown -R agentdvr:agentdvr '/AgentDVR'
    su -m agentdvr -c '/AgentDVR/Agent'
else
    # run as root if user creation failed (default behavior).
    echo "PUID/PGID is NOT SET thus User agentdvr does not exist. Running AgentDVR as $(whoami)..."
    su -m "$(whoami)" -c '/AgentDVR/Agent'
fi
}
CURRENT_PORT=$(cat /AgentDVR/Media/XML/current_port.txt)
CURRENT_PORT=$(expr "$CURRENT_PORT")
if [ -n "$WEBUI_PORT" ]; then
	if [[ "$WEBUI_PORT" =~ ^[0-9]+$ ]]; then
		if [ "$WEBUI_PORT" -le 65353 ] && [ "$WEBUI_PORT" -ge 0 ]; then
			if [ "$WEBUI_PORT" -ne "$CURRENT_PORT" ]; then
				cat /AgentDVR/Media/XML/config.xml | awk '{ x[NR] = $0 } END { for ( i=1 ; i<=NR ; i++ ) { if (x[i] ~ /<ServerPort>/ ) {x[i]=" <ServerPort>"$WEBUI_PORT"</ServerPort>"}print x[i] }} ' >/AgentDVR/Media/XML/new.xml
				rm -rf /AgentDVR/Media/XML/config.xml
				mv /AgentDVR/Media/XML/new.xml /AgentDVR/Media/XML/config.xml
				echo "$WEBUI_PORT" >/AgentDVR/Media/XML/port.txt
				echo "$WEBUI_PORT" >/AgentDVR/Media/XML/current_port.txt
			fi
		elif [ "$WEBUI_PORT" -le 50010 ] && [ "$WEBUI_PORT" -ge 50000 ]; then
			echo "Value of WEBUI_PORT Environment Variable is set $WEBUI_PORT, which is between 50000-5010. These ports are resurved for TURN Server Communications. Thus the WebUI Port is not changed."
		elif [ "$WEBUI_PORT" -eq 3478 ]; then
			echo "Value of WEBUI_PORT Environment Variable is set $WEBUI_PORT, which is reserved for STUN Server Communications. Thus the WebUI Port is not changed." 
		fi
	else
		echo "Non Numecic value has been entered in WEBUI_PORT Environment Variable. Thus WebUI Port is not Changed."
	fi
fi
/AgentDVR/banner.sh
DEBUG_MODE=$(echo "${DEBUG_MODE}" | tr '[:upper:]' '[:lower:]')
if [ "${DEBUG_MODE}" == 'yes' ] || [ "${DEBUG_MODE}" == 'ye' ] || [ "${DEBUG_MODE}" == 't' ] || [ "${DEBUG_MODE}" == 'y' ] || [ "${DEBUG_MODE}" == 'true' ]; then
	if [ -e /AgentDVR/Media/XML/customEntrypoint.sh ]; then
		bash /AgentDVR/Media/XML/customEntrypoint.sh
	else
		sleep infinity
	fi
else
	start_agent
fi
