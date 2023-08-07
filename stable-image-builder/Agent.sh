#!/bin/bash
date +%c > /run-timestamp
echo "This image was build on: $(cat /build-timestamp)"   
/AgentDVR/banner.sh
echo "This Container was started on: $(cat /run-timestamp)"
/AgentDVR/Agent
