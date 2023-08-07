#!/bin/bash

# Install script for AgentDVR/ Linux
cd /
name=$(whoami)
#add permissions for local device access
  adduser $name video
  usermod -a -G video $name
	curl --show-error --location "https://raw.githubusercontent.com/ispysoftware/agent-install-scripts/main/v2/AgentDVR.service" -o "AgentDVR.service"
	sed -i "s|AGENT_LOCATION|/AgentDVR|" AgentDVR.service
	sed -i "s|YOUR_USERNAME|$name|" AgentDVR.service
	  chmod 644 ./AgentDVR.service 
	  chown $name -R /AgentDVR
	  cp AgentDVR.service /etc/systemd/system/AgentDVR.service
	  systemctl daemon-reload 
      echo "Service Daemon RELOADED!" 
      systemctl enable AgentDVR 
      echo "AgentDVR.service ENABLED!" 
      systemctl start AgentDVR 
      echo "AgentDVR.service STARTED!"
exit 0