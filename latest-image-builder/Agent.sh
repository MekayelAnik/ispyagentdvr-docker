#!/bin/bash
date +%c > /run-timestamp
cat /AgentDVR/build-timestamp
/AgentDVR/banner.sh
echo "This Container was started on: $(cat /run-timestamp)"
/AgentDVR/Agent
