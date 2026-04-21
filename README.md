<h1>iSpy Agent DVR multi-arch image</h1>
<img alt="ispyagentdvr" src="https://www.ispyconnect.com/img/agent.webp">
<p>Official Agent DVR image. Website: <a href="https://www.ispyconnect.com" rel="nofollow noopener">https://www.ispyconnect.com</a>
</p>
<p align="center">
  <a href="https://www.gnu.org/licenses/gpl-3.0"><img alt="License: GPLv3" src="https://img.shields.io/badge/License-GPLv3-blue.svg"></a>
  <a href="https://hub.docker.com/r/mekayelanik/ispyagentdvr"><img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/mekayelanik/ispyagentdvr.svg"></a>
  <a href="https://hub.docker.com/r/mekayelanik/ispyagentdvr"><img alt="Docker Stars" src="https://img.shields.io/docker/stars/mekayelanik/ispyagentdvr.svg"></a>
  <a href="https://ghcr.io/mekayelanik/ispyagentdvr"><img alt="GHCR" src="https://img.shields.io/badge/GHCR-ghcr.io%2Fmekayelanik%2Fispyagentdvr-blue"></a>
  <a href="https://hub.docker.com/r/mekayelanik/ispyagentdvr"><img alt="Platforms" src="https://img.shields.io/badge/Platforms-amd64%20%7C%20arm64%20%7C%20arm%2Fv7-lightgrey"></a>
  <a href="https://github.com/MekayelAnik/ispyagentdvr-docker/stargazers"><img alt="GitHub Stars" src="https://img.shields.io/github/stars/MekayelAnik/ispyagentdvr-docker"></a>
  <a href="https://github.com/MekayelAnik/ispyagentdvr-docker/forks"><img alt="GitHub Forks" src="https://img.shields.io/github/forks/MekayelAnik/ispyagentdvr-docker"></a>
  <a href="https://github.com/MekayelAnik/ispyagentdvr-docker/issues"><img alt="GitHub Issues" src="https://img.shields.io/github/issues/MekayelAnik/ispyagentdvr-docker"></a>
  <a href="https://github.com/MekayelAnik/ispyagentdvr-docker/commits/main"><img alt="Last Commit" src="https://img.shields.io/github/last-commit/MekayelAnik/ispyagentdvr-docker.svg"></a>
</p>
<p><strong>DISCLAIMER:</strong> Buy me coffee link below is NOT affiliated in anyway with the main iSpy AgentDVR. The docker image publisher is NOT affiliated with the main iSpy AgentDVR either.</p>
<p align="center">
<a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
</a>
</p>
<h2>The architectures supported by this image are:</h2>
<table>
  <thead>
    <tr>
      <th align="center">Architecture</th>
      <th align="center">Available</th>
      <th>Tag</th>
       <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">x86-64</td>
      <td align="center">✅</td>
      <td>amd64-&lt;version tag&gt;</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">arm64</td>
      <td align="center">✅</td>
      <td>arm64v8-&lt;version tag&gt;</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">armhf</td>
      <td align="center">✅</td>
      <td>arm32v7-&lt;version tag&gt;</td>
      <td>Tested "WORKING" (4.8.2.0 and newer versions)</td>
    </tr>
  </tbody>
</table>
<h2><b>Anouncements:</b></h2>
<ul>
<li>  ⚠️⚠️⚠️ Directory structure reverted to <code>/AgentDVR</code> from <code>/home/agentdvr/AgentDVR</code>. It is <b>SPECIALLY IMPORTANT</b> to correctly apply this change in unRAID, Synology NAS and other GUID based container deployer. ⚠️⚠️⚠️</li>
<li>  ⚠️ Base image updated to <b>Debian Trixie</b> ⚠️</li>
<li>  ⚠️ ZSTD compression applied to reduce image size and save bandwidth. Docker Engine 23.0 or later and for Podman deployment Podman Machine v5.1 or later is required for image version 6.5.7.0 and later! ⚠️</li>
<li> ⚠️⚠️⚠️ <b>VERY IMPORTANT:</b> TURN Server Port range is changed from <code>50000-50010</code> to <code>50000-50100</code>. Please set the range in Docker CLI or Docker Compose to <code>50000-50100⚠️⚠️⚠️</code></li>
<li> The <strong>ARMHF</strong> image has been fixed. For <strong>ARM32-bit/ARMHF</strong> devices, use image version <strong>4.8.2.0</strong> or newer.</li>
<li> For GPU HW-Accelerated Encode/Decode please use version <strong>5.3.5.0 or NEWER</strong> images.</li>
<li> ⚠️⚠️⚠️ It is <b>Discouraged</b> to use BETA on mission-critical environments!!! </li>
<li> Read the <a href="https://www.ispyconnect.com/producthistory.aspx?productid=27" rel="nofollow noopener">update information</a> and use older tags with caution. </li>
</ul>

<table>
  <thead>
    <tr>
      <th align="center">Tag</th>
      <th align="center">Available</th>
      <th>Description</th>
       <th>Status</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">stable</td>
      <td align="center">✅</td>
      <td>"iSpy Agent DVR" Most Stable image to date</td>
      <td>Tested "WORKING". An image will be made "stable" if an image remains "latest" for at least 5 days</td>
    </tr>
    <tr>
      <td align="center">latest</td>
      <td align="center">✅</td>
      <td>"iSpy Agent DVR" Latest releases image</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">beta</td>
      <td align="center">⚠️</td>
      <td>"iSpy Agent DVR" BETA releases image</td>
      <td>⚠️ LATEST BETA for "BETA TESTING". Backup config before trying!!! Discouraged to use on mission-critical environments!!! ⚠️</td>
    </tr>
    <tr>
      <td align="center">7.4.2.0</td>
      <td align="center">✅</td>
      <td>"iSpy Agent DVR" Static version 7.4.2.0 image</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">7.2.4.0-beta</td>
      <td align="center">⚠️</td>
      <td>"iSpy Agent DVR" 7.2.4.0 beta release for testing</td>
      <td>⚠️ THOROUGH TESTING REQUIRED. Backup config before trying!!! Discouraged to use on mission-critical envirenments!!! ⚠️</td>
    </tr>
  </tbody>
</table>
<h2>Running Image :</h2>
<h3>docker-compose (recommended, <a href="https://itnext.io/a-beginners-guide-to-deploying-a-docker-application-to-production-using-docker-compose-de1feccd2893" rel="nofollow noopener">docs</a>) </h3>
<pre><code>---
services:
  ispyagentdvr:
    image: mekayelanik/ispyagentdvr:latest
    container_name: ispyagentdvr
    environment:
      - PUID=1000
      - PGID=1000
      - AGENTDVR_WEBUI_PORT=8090 
      - TZ=Asia/Dhaka
    volumes:
      - /path/to/config:/AgentDVR/Media/XML
      - /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media
      - /path/to/models:/AgentDVR/Media/Models
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50100:50000-50100/udp
    restart: unless-stopped
</code></pre>

<strong>Note:</strong> <p> - On Raspberry Pi and other low-power ARM SBCs, wait about 30 seconds after deployment before opening WebUI, then refresh if needed.</p>
<p> - With many cameras, startup may take longer.</p>

<h3>docker cli ( <a href="https://docs.docker.com/engine/reference/commandline/cli/" rel="nofollow noopener">docs</a>) </h3>
<pre><code>docker run -d \
  --name=ispyagentdvr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e AGENTDVR_WEBUI_PORT=8090
  -e TZ=Asia/Dhaka \
  -p 8090:8090 \
  -p 3478:3478/udp \
  -p 50000-50100:50000-50100/udp \
  -v /path/to/config:/AgentDVR/Media/XML \
  -v /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media \
  -v /path/to/models:/AgentDVR/Media/Models \
  -v /path/to/commands:/AgentDVR/Commands \
  --restart unless-stopped \
  mekayelanik/ispyagentdvr:latest
</code></pre>
<h3>Dedicated local IP using MACVLAN ( <a href="https://docs.docker.com/network/macvlan/" rel="nofollow noopener">docs</a>) </h3>
<pre><code>---
services:
  ispyagentdvr:
    image: ghcr.io/mekayelanik/ispyagentdvr:latest
    container_name: ispyagentdvr
    environment:
      - PUID=1000
      - PGID=1000
      - AGENTDVR_WEBUI_PORT=8090 
      - TZ=Asia/Dhaka
    volumes:
      - /path/to/config:/AgentDVR/Media/XML
      - /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media
      - /path/to/models:/AgentDVR/Media/Models
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50100:50000-50100/udp
    restart: unless-stopped
    hostname: ispyagentdvr
    domainname: local
    mac_address: AB-BC-C0-D1-E2-EF
    networks:
      macvlan-1:
        ipv4_address: 192.168.2.12
networks:
  macvlan-1:
    name: macvlan-1
    external: True</code></pre>
<p>To make MACVLAN work, set valid values for <code>mac_address</code>, <code>ipv4_address</code>, <code>subnet</code>, <code>ip_range</code>, and <code>gateway</code>.</p>
<p>In the case of MACVLAN, you must access the WebUI using <code>http://ipv4_address:8090</code>
</p>
<h2>GPU HW-Acceleration <strong>(Tested "WORKING" on images with tag 5.3.5.0 or NEWER)</strong></h2>
<p>One must use images from 5.3.5.0 or NEWER images to get the provisioned GPU HW-Acceleration. Older images will not work. If you face any issues, please report this on GitHub of this image. The GitHub link can be found at the bottom of this page.</p>
<h3>docker-compose (recommended, <a href="https://itnext.io/a-beginners-guide-to-deploying-a-docker-application-to-production-using-docker-compose-de1feccd2893" rel="nofollow noopener">docs</a>) </h3>
<h3><strong>One must be able to pass GPU (Rendering devices) to the container as is instructed below!</strong></h3>
<pre><code>---
services:
  ispyagentdvr:
    image: ghcr.io/mekayelanik/ispyagentdvr:latest
    container_name: ispyagentdvr
    environment:
      - PUID=1000
      - PGID=1000
      - AGENTDVR_WEBUI_PORT=8090
      - TZ=Asia/Dhaka
    volumes:
      - /path/to/config:/AgentDVR/Media/XML
      - /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media
      - /path/to/models:/AgentDVR/Media/Models
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50100:50000-50100/udp
    restart: unless-stopped
</code></pre>

<h3>docker cli ( <a href="https://docs.docker.com/engine/reference/commandline/cli/" rel="nofollow noopener">docs</a>) </h3>
<pre><code>docker run -d \
  --name=ispyagentdvr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e AGENTDVR_WEBUI_PORT=8090 \
  -e TZ=Asia/Dhaka \
  -p 8090:8090 \
  -p 3478:3478/udp \
  -p 50000-50100:50000-50100/udp \
  -v /path/to/config:/AgentDVR/Media/XML \
  -v /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media \
  -v /path/to/models:/AgentDVR/Media/Models \
  -v /path/to/commands:/AgentDVR/Commands \
  --restart unless-stopped \
  mekayelanik/ispyagentdvr:latest</code></pre>
<h3>For Nvidia GPUs</h3>
<p>To get GPU Hardware acceleration from Nvidia, user <strong>MUST INSTALL THE "LATEST" Nvidia Drivers & Nvidia Container Toolkit on the Host Machine/Server/VM/LXC</strong> provided by Nvidia. Instructions for <strong>Nvidia Container Toolkit</strong> can be found here:</p>
<a href="https://github.com/NVIDIA/nvidia-container-toolkit" rel="nofollow noopener">Nvidia-Container-Toolkit</a>
<p>We added the necessary environment variable that will utilize all the features available on a GPU on the host. Once Nvidia container runtime is installed on your host you will need to re/create the docker container with the nvidia container runtime `--runtime=nvidia` and add an environment variable `-e NVIDIA_VISIBLE_DEVICES=all` (can also be set to a specific gpu's UUID, this can be discovered by running `nvidia-smi --query-gpu=gpu_name,gpu_uuid --format=csv` ). NVIDIA automatically mounts the GPU and drivers from your host into the AgentDVR docker container.
</p>
<h3>For AMD GPUs & iGPUs</h3>
<p>The following have to be added in docker-compose file/docker-cli cm respectively</p>
<p><strong>docker compose</strong></p>
<pre><code>devices:
    - /dev/dri/renderD128:/dev/dri/renderD128
    - /dev/dri/card0:/dev/dri/card0
    - /dev/kfd:/dev/kfd</code></pre>
<p><strong>docker cli</strong></p>
<pre><code>--device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri:/dev/dri/card0 --device /dev/kfd:/dev/kfd</code></pre>
<h3>For Intel GPUs & iGPUs</h3>
<p>The following have to be added in docker-compose file/docker-cli cm respectively</p>
<p><strong>docker compose</strong></p>
<pre><code>devices:
    - /dev/dri/renderD128:/dev/dri/renderD128
    - /dev/dri/card0:/dev/dri/card0</code></pre>
<p><strong>docker cli</strong></p>
<pre><code>--device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri/card0:/dev/dri/card0</code></pre>

<h3>For Rockchip SBC's integrated VPU, use the CLI command below</h3>
<pre><code>docker run -d \
  --name=ispyagentdvr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e AGENTDVR_WEBUI_PORT=8090 \
  -e TZ=Asia/Dhaka \
  -p 8090:8090 \
  -p 3478:3478/udp \
  -p 50000-50100:50000-50100/udp \
  -v /path/to/config:/AgentDVR/Media/XML \
  -v /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media \
  -v /path/to/models:/AgentDVR/Media/Models \
  -v /path/to/commands:/AgentDVR/Commands \
  --restart unless-stopped \
`for dev in dri dma_heap mali0 rga mpp_service \
   iep mpp-service vpu_service vpu-service \
   hevc_service hevc-service rkvdec rkvenc vepu h265e ; do \
  [ -e "/dev/$dev" ] && echo " --device /dev/$dev"; \
 done` 
  mekayelanik/ispyagentdvr:latest</code></pre>
<h4>DISCLAIMER: Jellyfin FFMPEG and corresponding ideas were used in this image to enable the HW-Acceleration</h4>
<h2>Parameters</h2>
<p>Container images use runtime parameters. These are separated by a colon and indicate <code>&lt;external&gt;:&lt;internal&gt;</code>. For example, <code>-p 8090:80</code> exposes port <code>80</code> inside the container on host port <code>8090</code>. </p>
<table>
  <thead>
    <tr>
      <th align="center">Parameter</th>
      <th>Function</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">
        <code>-p 8090</code>
      </td>
      <td>Map AgentDVR WebUI Port to HOST</td>
    </tr>
    <tr>
      <td align="center">
        <code>-p 3478/udp</code>
      </td>
      <td>Map Main port used for TURN server communication to HOST</td>
    </tr>
    <tr>
      <td align="center">
        <code>-p 50000-50100//udp</code>
      </td>
      <td>Map Ports from AgentDVR to HOST, to be used to create connections or WebRTC. These will be used as needed</td>
    </tr>
    <tr>
      <td align="center">
        <code>-e PUID=1000</code>
      </td>
      <td>For UserID - see below for explanation</td>
    </tr>
    <tr>
      <td align="center">
        <code>-e PGID=1000</code>
      </td>
      <td>For GroupID - see below for explanation</td>
    </tr>
    <tr>
      <td align="center">
        <code>-e TZ=Asia/Dhaka</code>
      </td>
      <td>Specify a timezone to use, see this <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List" rel="nofollow noopener">list</a>. </td>
    </tr>
    <tr>
      <td align="center">
        <code>-e AGENTDVR_WEBUI_PORT=8090</code>
      </td>
      <td>Specify a Port to Expose AgentDVR WebUI</td>
    </tr>
    <tr>
      <td align="center">
        <code>-v /AgentDVR/Media/XML</code>
      </td>
      <td>Contains all relevant configuration files.</td>
    </tr>
    <tr>
      <td align="center">
        <code>-v /AgentDVR/Media/WebServerRoot/Media</code>
      </td>
      <td>Location of Surveillance Recordings on disk.</td>
    </tr>
    <tr>
      <td align="center">
        <code>-v /AgentDVR/Media/Models</code>
      </td>
      <td>Model files location for AgentDVR.</td>
    </tr>
    <tr>
      <td align="center">
        <code>-v /AgentDVR/Commands </code>
      </td>
      <td>Location to store desired iSpy Agent DVR Commands.</td>
    </tr>
  </tbody>
</table>
<h2>User / Group Identifiers</h2>
<p>When using volumes ( <code>-v</code> flags) permissions issues can arise between the host OS and the container, One can avoid this issue by allowing you to specify the user <code>PUID</code> and group <code>PGID</code>. </p>
<p>Ensure any volume directories on the host are owned by the same user you specify and any permissions issues will vanish like magic.</p>
<p>In this instance <code>PUID=1000</code> and <code>PGID=1000</code>, to find yours use <code>id user</code> as below: </p>
<pre><code>$ id username
uid=1000(docker user) gid=1000(docker group) groups=1000(docker group)</code></pre>
<h2>For iSpy Agent DVR specific user guide visit:</h2>
<a href="https://www.ispyconnect.com/userguide-agent-dvr.aspx" rel="nofollow noopener">https://www.ispyconnect.com/userguide-agent-dvr.aspx</a>
</p>
<h2>Non host network use:</h2>
<p> To use a Non-host network, you will need to open up ports for this to properly work, thus the UDP ports listed in the sample runs.</p>
<p>To access WebUI go to the container's <code>http://container's ip:8090</code> or <code>http://ipv4_address:8090</code>
</p>
<h2>Updating Info</h2>
<p>Below are the instructions for updating containers:</p>
<h3>Via Docker Compose (recommended)</h3>
<ul>
  <li>Update all images: <code>docker compose pull</code>
    <ul>
      <li>or update a single image: <code>docker compose pull ispyagentdvr</code>
      </li>
    </ul>
  </li>
  <li>Let compose update all containers as necessary: <code>docker compose up -d</code>
    <ul>
      <li>or update a single container (recommended): <code>docker compose up -d ispyagentdvr</code>
      </li>
    </ul>
  </li>
  <li>To remove the old unused images run: <code>docker image prune</code>
  </li>
</ul>
<h3>Via Docker Run</h3>
<ul>
  <li>Update the image: <code>docker pull mekayelanik/ispyagentdvr:latest</code>
  </li>
  <li>Stop the running container: <code>docker stop ispyagentdvr</code>
  </li>
  <li>Delete the container: <code>docker rm ispyagentdvr</code>
  </li>
  <li>Recreate a new container with the same docker run parameters as instructed above (if mapped correctly to a host folder, your <code>/AgentDVR/Media/XML</code> folder and settings will be preserved) </li>
  <li>To remove the old unused images run: <code>docker image prune</code>
  </li>
</ul>
<h3>Via <a href="https://containrrr.dev/watchtower/" rel="nofollow noopener">Watchtower</a> auto-updater (only use if you don't remember the original parameters)</h3>
<ul>
  <li>
    <p>Pull the latest image at its tag and replace it with the same env variables in one run:</p>
    <pre>
<code>docker run --rm \
-v /var/run/docker.sock:/var/run/docker.sock \
containrrr/watchtower\
--run-once ispyagentdvr</code></pre>
  </li>
  <li>
    <p>To remove the old unused images run: <code>docker image prune</code>
    </p>
  </li>
</ul>
<h3>Image Update Notifications - Diun (Docker Image Update Notifier)</h3>
<ul>
  <li>You can also use <a href="https://crazymax.dev/diun/" rel="nofollow noopener">Diun</a> for update notifications. Other tools that automatically update containers unattended are not encouraged </li>
</ul>
<h2>Migration Notes:</h2>
<h4>If you had the old format of audio and video volumes please move them to the new media folder before starting the container again.</h4>
<p>It would look something like this:
<pre>
<code>mkdir -p /ispyagentdvr/media/old && \
mv /path/to/recordings/audio /ispyagentdvr/media/old && \
mv /path/to/recordings/video /ispyagentdvr/media/old</code></pre>


<h2> NOTES: </h2>
<p><strong> - Audio playback on Linux host: </strong> If you experiencing sound playback issues on Linux server hosts (Debian/Ubuntu etc.), i.e. Action sound won't play through server's speaker, add these lines to docker-compose.yml:</p>
<pre><code>    group_add:
        - audio
    devices:
        - /dev/snd:/dev/snd
</code></pre>
<p><strong> - ARM SBCs: </strong>Raspberry Pi 4+ may support limited acceleration with proper host setup. Performance can vary; if you get a reliable VAAPI/VPU configuration, share it via GitHub and it can be documented with credit.</p>
<p><strong> - Things to make sure before Submitting a issue:</strong> </p>
  <ul>
    <li>Update your <strong>Docker Engine</strong> to the latest available, specially on OSX. After updating the docker engine please check if the issue has been resolved.
    </li>
    <li>Inspect the <code>AgentDVR-IP:AGENTDVR_WEBUI_PORT/logs.html</code> for Error list
    </li>
    <li>If you intend to run this image on Raspberry Pi 5 then use <strong>Ubuntu or Ubuntu Server</strong> as your OS. There is a bug in Debian that fatally affects the execution of AgentDVR and many other applications that are written on .Net Core. Other Raspberry Pi doesn't have this issue at the time of writing this.
    </li>
    <li>When reporting issues, include your Docker Compose/Docker CLI deployment command and relevant <code>logs.html</code> output.
    </li>
  </ul>

<p><strong> - Major Changes</strong></p>
<ul>
<li><strong>7.2.0.0:</strong> - ⚠️⚠️⚠️ NEW directory mapping required for persistant AI model storage<code>/AgentDVR/Media/Models</code> ⚠️⚠️⚠️</li> 
<li><strong>6.6.2.0:</strong> - ⚠️⚠️⚠️ Directory structure reverted to <code>/AgentDVR</code> from <code>/home/agentdvr/AgentDVR</code>. It is <b>SPECIALLY IMPORTANT</b> to correctly apply this change in unRAID, Synology NAS and other GUID based container deployer. ⚠️⚠️⚠️</li> 
<li><strong>6.6.2.0:</strong> - ⚠️⚠️⚠️ Base image changed to <b>Debian Trixie</b> from Bookworm (mekayelanik:ispyagentdvr-trixie-slim-vlc-jellyfin-ffmpeg-7.1.1-7-intel-25.31.34666.3) ⚠️⚠️⚠️</li>
<li><strong>6.6.2.0:</strong> - ✅ UPDATED: Intel driver Version to: 25.31.34666.3 and AMD Mesa Driver Version to: 25.2.2-1</li>
<li><strong>6.6.2.0:</strong> - ⚠️⚠️⚠️ Armhf will not get any Jellyfin FFMEG from now on as the suppoprt has been dropped by Jellyfin. Instead, FFMEG from Debian SID will be used for ARMHF builds. ⚠️⚠️⚠️</li>
<li><strong>6.5.7.0:</strong> - ⚠️⚠️⚠️ ZSTD compression applied to reduce image size and save bandwidth. Docker Engine 23.0 or later and in case of Podman deployment, Podman Machine v5.1 or later is required for image version 6.5.7.0 and later! ⚠️⚠️⚠️</li> 
<li><strong>6.3.4.0:</strong> - ✅ Regular version updated to 6.3.4.0. Updated Intel GPU driver to Comute Runtime Version: 25.18.33578.6, AMD Mesa Driver Version: 25.0.7-1 and updated jellyfin-ffmpeg to 7.1.1-6</li>
<li><strong>6.1.3.0:</strong> - ✅ Regular version updated to 6.1.3.0. Using BETA images in a mission-critical environment is STRICTLY DISCOURAGED ⚠️</li>
<li><strong>6.0.9.0:</strong> - ⚠️⚠️⚠️ Updated Intel GPU driver and updated jellyfin-ffmpeg to 7.0.2-9 ⚠️⚠️⚠️</li> 
<li><strong>6.0.1.0:</strong> - ⚠️⚠️⚠️ Added driver support for Intel Battlemage GPUs ⚠️⚠️⚠️</li> 
<li><strong>5.8.4.0:</strong> - ⚠️⚠️⚠️ Config files file format changed from XML to JSON ⚠️⚠️⚠️</li> 
<li><strong>5.8.1.0:</strong> - ⚠️ FFMPEG version bumped from 6.0.1 to 7.0.2</li> 
<li><strong>5.8.1.0:</strong> - <code>mekayelank/ispyagentdvr</code> image is now fully backword compatible with <code>doitandbedone/ispyagentdvr</code> image. From now on, you don't have to change the directory mapping to switch from <code>doitandbedone/ispyagentdvr</code> to <code>mekayelank/ispyagentdvr</code>, <b>UNLESS you are using unRAID/Synology NAS or other GUI based container deployer. In that case, you will have to follow the contents of the documentation to deploy this image</b></li>
</ul>

<h2>Support</h2>
<p align="center">
<a href="https://07mekayel07.gumroad.com/coffee" target="_blank">
<img src="https://cdn.buymeacoffee.com/buttons/v2/default-yellow.png" alt="Buy Me A Coffee" width="217" height="60">
</a>
</p>

<h2>Issues & Requests</h2>
<p> To submit this Docker image specific issues or requests visit this docker image's Github Link: <a href="https://www.github.com/MekayelAnik/ispyagentdvr-docker" rel="nofollow noopener">https://www.github.com/MekayelAnik/ispyagentdvr-docker</a>
</p>
<p> For iSpy AgentDVR-related issues and requests, please visit: <a href="https://www.reddit.com/r/ispyconnect/" rel="nofollow noopener">https://www.reddit.com/r/ispyconnect/</a>
</p>
<p> To have a deeper dive into the custom base image of this container, please visit: <a href="https://github.com/MekayelAnik/ispyagentdvr-base-image" rel="nofollow noopener">https://github.com/MekayelAnik/ispyagentdvr-base-image</a>
</p>