FROM debian:bookworm-slim
LABEL AUTHOR=https://github.com/MekayelAnik

RUN mkdir /entrypoint && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install systemd python3 curl unzip ffmpeg -y && \
    dpkg -L systemd | grep ".service$" | tr '\n' '\0' | xargs -0 -n1 -i rm -v {} && \
	rm /etc/fstab
	
ADD --chmod=555 https://raw.githubusercontent.com/gdraheim/docker-systemctl-replacement/v1.5.7106/files/docker/systemctl3.py /bin/systemctl
COPY --chmod=555 agent-setup.sh /entrypoint/agent-setup.sh
COPY --chmod=555 entrypoint.sh /entrypoint/entrypoint.sh
RUN bash /entrypoint/agent-setup.sh

RUN chmod 555 /usr/bin/systemctl && \
    systemctl daemon-reload && \
    echo "Service Daemon RELOADED!" && \
    systemctl enable AgentDVR && \
    echo "AgentDVR.service ENABLED!" && \
    systemctl start AgentDVR && \
    echo "AgentDVR.service STARTED!" 

# Clean up
RUN apt-get -y --purge remove curl unzip  && \ 
    apt-get autoremove -y && \
    apt-get clean && \
    chmod 555 /bin/systemctl && \
    rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*  && \
    rm -rf /entrypoint/agent-setup.sh

# Docker needs to run a TURN server to get webrtc traffic to and from it over forwarded ports from the host
# These are the default ports. If the ports below are modified here you'll also need to set the ports in XML/Config.xml
# for example <TurnServerPort>3478</TurnServerPort><TurnServerMinPort>50000</TurnServerMinPort><TurnServerMaxPort>50010</TurnServerMaxPort>
# The main server port is overridden by creating a text file called port.txt in the root directory containing the port number, eg: 8090
# To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.1.12:8090/

# Main UI port
EXPOSE 8090

# TURN server port
EXPOSE 3478/udp

# TURN server UDP port range
EXPOSE 50000-50010/udp

# If anyone chooses to use HTTP port
EXPOSE 80

# If anyone chooses to use HTTPS port
EXPOSE 443

# Data volumes
VOLUME ["/AgentDVR/Media/XML", "/AgentDVR/Media/WebServerRoot/Media", "/AgentDVR/Commands" ]

# Define service entrypoint
CMD ["bash", "/entrypoint/entrypoint.sh"]