#!/bin/bash
echo "Cleaning Up the image..........."
apt-get -y --purge --allow-remove-essential remove unzip wget
apt-get autoremove -y
apt-get clean
rm -vrf /var/lib/apt/lists/*
rm -vrf /var/cache/apt/archives/*
rm -vrf /AgentDVR/build_data
cd /AgentDVR
rm -vrf build_data agent-register.sh agent-reset.sh agent-reset-account.sh agent-reset-local-login.sh setup-ffmpeg-linux.sh setup-ffmpeg-osx.sh agent-uninstall-service.sh agent-update.sh
