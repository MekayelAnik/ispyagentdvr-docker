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
    echo "Publishing Stable image(s)..."
else
    echo 'RUN apt-get update && \
    if ! command -v sudo >/dev/null 2>&1; then \
        echo "sudo is not installed. Installing sudo..." && \
        apt-get update && \
        apt-get install -y sudo; \
    fi && \
    # Clean up to reduce image size
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*'  >> ./"Dockerfile.$REPO_NAME"
    echo "Building and publishing image(s)..."
    echo 'RUN useradd -m -d /home/agentdvr -s /bin/bash -u 1000 agentdvr && \
            echo "agentdvr:agentdvr" | chpasswd && \
            chown -R agentdvr:agentdvr /home/agentdvr && \
            chmod 775 /home/agentdvr && \
            mkdir -p /home/agentdvr/AgentDVR/Commands && \
            chmod -R 777 /home/agentdvr/AgentDVR/Commands && \
            name="$(whoami)" && \
            echo "Adding permission for USER:$name to local device (GPU) access" && \
            usermod -aG video "$name" && \
            echo "Added permission for USER:$name to GPU access" && \
            usermod -aG video agentdvr && \
            echo "Added permission for USER:agentdvr to GPU access" && \
            usermod -aG sudo agentdvr && \
            usermod -aG "$name" agentdvr && \
            usermod -aG agentdvr "$name" && \
            echo "agentdvr ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers' >> ./"Dockerfile.$REPO_NAME"
    echo -e '
COPY --chown=agentdvr:agentdvr ./resources /home/agentdvr/AgentDVR
RUN chmod -R 0774 /home/agentdvr/AgentDVR && \
    bash /home/agentdvr/AgentDVR/setup.sh  && \
    bash /home/agentdvr/AgentDVR/cleanup.sh  && \
    rm -vrf /home/agentdvr/AgentDVR/cleanup.sh
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
    # Disable .NET file locking
    ENV DOTNET_SYSTEM_IO_DISABLEFILELOCKING=1
    ENV DOTNET_CLI_TELEMETRY_OPTOUT=1

    # Main UI port
    EXPOSE 8090

    # HTTPS port
    EXPOSE 443

    # STUN server port
   EXPOSE 3478/udp

    # TURN server UDP port range
    EXPOSE 50000-50100/udp

   EXPOSE 50000-50100/udp 50000-50100/tcp

    #Data volumes
   VOLUME ["/AgentDVR/Media/XML", "/AgentDVR/Media/WebServerRoot/Media", "/AgentDVR/Commands"]

>>>>>>> 17ff8b4577c1eee1460f95bfe1c291caba779ba6
    # Define service entrypoint
    CMD ["/home/agentdvr/AgentDVR/Agent.sh"]'  >> ./"Dockerfile.$REPO_NAME"
fi
