# Use DEBIAN BOOKWORM-SLIM
FROM debian:bookworm-slim
ARG DEBIAN_FRONTEND=noninteractive 
ARG TZ=Asia/Dhaka
RUN mkdir /AgentDVR
COPY --chmod=555 dependency.sh /AgentDVR
COPY --chmod=555 setup.sh /AgentDVR
COPY --chmod=555 ffmpeg.sh /AgentDVR
COPY --chmod=555 banner.sh /AgentDVR
COPY --chmod=555 Agent.sh /AgentDVR
COPY --chmod=444 build-timestamp /AgentDVR
# Add to source.list
#RUN bash /AgentDVR/source.sh

# Download and install distro Updates
#RUN bash /AgentDVR/update.sh

# Download and install dependencies
RUN bash /AgentDVR/dependency.sh
	
# Download/Install iSpy Agent DVR: 
RUN bash /AgentDVR/setup.sh

# Install ffmpeg
RUN bash /AgentDVR/ffmpeg.sh

RUN apt-get -y --purge --allow-remove-essential remove unzip wget && \ 
    apt-get autoremove -y && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/* && \
    rm -rf /AgentDVR/dependency.sh && \
    rm -rf /AgentDVR/setup.sh && \
    rm -rf /AgentDVR/source.sh && \
    rm -rf /AgentDVR/update.sh && \
    rm -rf /AgentDVR/ffmpeg.sh

# Docker needs to run a TURN server to get webrtc traffic to and from it over forwarded ports from the host
# These are the default ports. If the ports below are modified here you'll also need to set the ports in XML/Config.xml
# for example <TurnServerPort>3478</TurnServerPort><TurnServerMinPort>50000</TurnServerMinPort><TurnServerMaxPort>50010</TurnServerMaxPort>
# The main server port is overridden by creating a text file called port.txt in the root directory containing the port number, eg: 8090
# To access the UI you must use the local IP address of the host, NOT localhost - for example http://192.168.1.12:8090/

# Define default environment variables
ENV PATH=/usr/local/sbin:/usr/local/bin:/usr/sbin:/usr/bin:/sbin:/bin
# Fix a memory leak on encoded recording
ENV MALLOC_TRIM_THRESHOLD_=100000

# Main UI port
EXPOSE 8090

# HTTPS port
EXPOSE 443

# STUN server port
EXPOSE 3478/udp

# TURN server UDP port range
EXPOSE 50000-50010/udp

# Data volumes
VOLUME ["/AgentDVR/Media/XML", "/AgentDVR/Media/WebServerRoot/Media", "/AgentDVR/Commands"]

# Define service entrypoint
CMD ["/AgentDVR/Agent.sh"]