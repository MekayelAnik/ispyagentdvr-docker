#!/bin/bash
REPO_NAME='ispyagentdvr-docker'
BASE_IMAGE=$(cat ./resources/build_data/base-image)
AGENTDVR_VERSION=$(cat ./resources/build_data/version)
AGENTDVR_VERSION="${AGENTDVR_VERSION//\_/\.}" 
echo "ARG BASE_IMAGE=$BASE_IMAGE" > ./"Dockerfile.$REPO_NAME"
echo "ARG AGENTDVR_VERSION=$AGENTDVR_VERSION" >> ./"Dockerfile.$REPO_NAME"
echo "
FROM $BASE_IMAGE" >> ./"Dockerfile.$REPO_NAME"
if [ -e ./resources/build_data/publication ]; then
    echo "Publishing Stable image(s)"
else
    echo "Building and publishing image(s)..."
    echo -e '
    ADD --chmod=555 ./resources /AgentDVR

    RUN bash /AgentDVR/setup.sh
    RUN bash /AgentDVR/cleanup.sh
    RUN rm -vrf /AgentDVR/setup.sh /AgentDVR/cleanup.sh
    ' >> ./"Dockerfile.$REPO_NAME"
    echo -e "# Docker needs to run a TURN server to get webrtc traffic to and from it over forwarded ports from the host" >> ./"Dockerfile.$REPO_NAME"
    echo -e "# These are the default ports. If the ports below are modified here you'll also need to set the ports in XML/Config.xml" >> ./"Dockerfile.$REPO_NAME"
    echo -e "# for example <TurnServerPort>3478</TurnServerPort><TurnServerMinPort>50000</TurnServerMinPort><TurnServerMaxPort>50010</TurnServerMaxPort>" >> ./"Dockerfile.$REPO_NAME"
    echo -e "# The main server port is overridden by creating a text file called port.txt in the root directory containing the port number, eg: 8090" >> ./"Dockerfile.$REPO_NAME"
    echo -e "# To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.1.12:8090/
    " >> ./"Dockerfile.$REPO_NAME"
    echo -e '# Define default environment variables
    ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin

    # Fix a memory leak on encoded recording
    ENV MALLOC_TRIM_THRESHOLD_=100000

    # Main UI port
    EXPOSE 8090

    # HTTPS port
   EXPOSE 443

    # STUN server port
   EXPOSE 3478/udp 3478/tcp

    # TURN server UDP port range
   EXPOSE 50000-50100/udp 50000-50100/tcp

    #Data volumes
   VOLUME ["/AgentDVR/Media/XML", "/AgentDVR/Media/WebServerRoot/Media", "/AgentDVR/Commands"]

    # Define service entrypoint
    CMD ["/AgentDVR/Agent.sh"]'  >> ./"Dockerfile.$REPO_NAME"
fi
