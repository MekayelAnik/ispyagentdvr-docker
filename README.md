<h1>iSpy Agent DVR multi-arch image</h1>
<img alt="ispyagentdvr" src="https://ispycontent.azureedge.net/img/ispy2.png">
<p>This is an unofficial multi-aarch docker image of Agent DVR of iSpy created for multiplatform support. iSpy Agent DVR creates a local server for IP cameras to be managed. Official Website: <a href="https://www.ispyconnect.com" rel="nofollow noopener">https://www.ispyconnect.com</a>
</p>
<img alt="Docker Pulls" src="https://img.shields.io/docker/pulls/mekayelanik/ispyagentdvr.svg"><img alt="Docker Stars" src="https://img.shields.io/docker/stars/mekayelanik/ispyagentdvr.svg">
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
<h2>Anouncements:</h2>
<p> - <b>PLEASE NOTE: Beta version (5.8.1.0 & 5.8.2.0) of iSpyagentDVR has been released for all the BRAVE HEARTED iSpyAgentDVR lovers to test the BLEEDING EDGE!</b></p>
<strong> ⚠️⚠️⚠️ WARNNING!!! Beta versions should not be used in mission critical sytems! ⚠️⚠️⚠️</strong>

<p> - <b>The following possible BREAKING CHANGES will be present in every future deployments</b></p>
<ul>
<li><strong> - FFMPEG version bumped from 6.0.1 to 7.0.2</strong></li> 
<li><strong> - DOTNET version bumped to 9.0</strong></li>
<li><strong> - Environment Variable WEBUI_PORT is now changed to AGENTDVR_WEBUI_PORT. Those who use Environment Variable to change the Port for Web UI, please use AGENTDVR_WEBUI_PORT from now on.</strong></li>
<li><strong> - TURN Server Port range changed from 50000-50010 to 50000-50100. Please set the range in Docker CLI or Docker Compose to 50000-50100</strong></li>
</ul>
<p> - <b>The Following images: <code>gpu-hwaccel-latest</code>,<code>vlc-hwaccel-latest</code> & <code>vlc-support-latest</code> will be taken down on 1st August 2024. Some images were re-uploaded. The Versions that have been re-uploaded are from 5.3.5.0 to the 5.6.0.0 AgentDVR versions. Only the Default tags were re-uploaded & do incorporate all the features combined that were avalable on the previously maintained 4 types of images in itself. Sorry for the inconvenience!</b>This is done inorder to Raid Bug detection, complexity reduction and ease of maintanance</p>
<p> - Alhamdulillah, The <strong>ARMHF</strong> image has been fixed. Special Thanks To <strong> Sean T</strong> for fixing the underlying issues. For <strong>ARM32-bit/ARMHF</strong> devices, please download image version greater or equal to <strong>4.8.2.0</strong>.</p>
<p> - For GPU HW-Accelarated Encode/Decode please use version <strong>5.3.5.0 or NEWER</strong> images</p>
<h3>This image provides various versions that are available via tags. Please read the <a href="https://www.ispyconnect.com/producthistory.aspx?productid=27" rel="nofollow noopener">update information</a> carefully and exercise caution when using "older versions" tags as they tend to contain unfixed bugs. </h3>
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
      <td>"iSpy Agent DVR" Most Stable image till date</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">latest</td>
      <td align="center">✅</td>
      <td>"iSpy Agent DVR" Latest releases image</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">5.8.0.0</td>
      <td align="center">✅</td>
      <td>"iSpy Agent DVR" Static version 5.8.0.0 image</td>
      <td>Tested "WORKING"</td>
    </tr>
    <tr>
      <td align="center">5.8.2.0-beta</td>
      <td align="center">⚠️</td>
      <td>"iSpy Agent DVR" beta realese for testing</td>
      <td>Needs thorough Testing</td>
    </tr>
  </tbody>
</table>
<h2>Running Image :</h2>
<p>Here are some example snippets to help you get started creating a container.</p>
<h3>docker-compose (recommended, <a href="https://itnext.io/a-beginners-guide-to-deploying-a-docker-application-to-production-using-docker-compose-de1feccd2893" rel="nofollow noopener">click here for more info</a>) </h3>
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
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50100:50000-50100/udp
    restart: unless-stopped
</code></pre>

<strong>Note:</strong> <p> - In the case of Raspberry Pi and other low power ARM SBCs, please hit the WebUI URL atleast 30 seconds after the container deployment. A few seconds maybe required by the ARM processors to kick start the needed services. Before this time you may not get response in the web browser. Also at the first time, you may have to refresh the WebUI a couple of times for the UI to get fully loaded.</p>
<p> - Also if you have a large number of Camera, the boot time will increase accordingly. So please be patient and have a look in the AgentDVR docker container log.</p>

<h3>docker cli ( <a href="https://docs.docker.com/engine/reference/commandline/cli/" rel="nofollow noopener">click here for more info</a>) </h3>
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
  -v /path/to/commands:/AgentDVR/Commands \
  --restart unless-stopped \
  mekayelanik/ispyagentdvr:latest
</code></pre>
<h3>If anyone wishes to give dedicated Local IP to iSpy Agent DVR container using MACVLAN ( <a href="https://docs.docker.com/network/macvlan/" rel="nofollow noopener">click here for more info</a>) </h3>
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
<p>In oreder to macvlan work properly, you must map any valid MAC address to <code>mac_address:</code>. Also you muat map any valid IP address in your <code>ip_range</code> to <code>ipv4_address:</code>.This will be your containr's IP. Then you must map your Router's Local IP Subnet to <code>subnet:</code> After that you must map your Desired Local IP range within the subnet to <code>ip_range:</code> Finally you must map your Router's LAN IP Address <code>gateway:</code>
</p>
<p>In the case of MACVLAN, you must access the WebUI using <code>http://ipv4_address:8090</code>
</p>
<h2>GPU HW-Acceleration <strong>(Tested "WORKING" on images with tag 5.3.5.0 or NEWER)</strong></h2>
<p>One must use images from 5.3.5.0 or NEWER image to get the provisioned GPU HW-Acceleration. Older images will not work. If you face any issues please report in github of this image. github link can be found at the bottom of this page.</p>
<h3>docker-compose (recommended, <a href="https://itnext.io/a-beginners-guide-to-deploying-a-docker-application-to-production-using-docker-compose-de1feccd2893" rel="nofollow noopener">click here for more info</a>) </h3>
<h3><strong>One must be able to pass GPU (Redering devices) to the container as is instructed below!</strong></h3>
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
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50100:50000-50100/udp
    restart: unless-stopped
</code></pre>

<h3>docker cli ( <a href="https://docs.docker.com/engine/reference/commandline/cli/" rel="nofollow noopener">click here for more info</a>) </h3>
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
  -v /path/to/commands:/AgentDVR/Commands \
  --restart unless-stopped \
  mekayelanik/ispyagentdvr:latest</code></pre>
<h3>For Nvidia GPUs</h3>
<p>To get GPU Hardware acceleration from Nvidia, user <strong>MUST INSTALL THE "LATEST" Nvidia Drivers & Nvidia Container Toolkit on the Host Machine/Server/VM/LXC</strong> provided by Nvidia. Instructions for <strong>Nvidia Container Toolkit</strong> can be found here:</p>
<a href="https://github.com/NVIDIA/nvidia-container-toolkit" rel="nofollow noopener">Nvidia-Container-Toolkit</a>
<p>We added the necessary environment variable that will utilise all the features available on a GPU on the host. Once nvidia-docker is installed on your host you will need to re/create the docker container with the nvidia container runtime `--runtime=nvidia` and add an environment variable `-e NVIDIA_VISIBLE_DEVICES=all` (can also be set to a specific gpu's UUID, this can be discovered by running `nvidia-smi --query-gpu=gpu_name,gpu_uuid --format=csv` ). NVIDIA automatically mounts the GPU and drivers from your host into the AgentDVR docker container.
</p>
<h3>For AMD GPUs & iGPUs</h3>
<p>The Followings have to be added in docker-compose file/docker-cli cm respectively</p>
<p><strong>docker compose</strong></p>
<pre><code>devices:
    - /dev/dri/renderD128:/dev/dri/renderD128
    - /dev/dri/card0:/dev/dri/card0
    - /dev/kfd:/dev/kfd</code></pre>
<p><strong>docker cli</strong></p>
<pre><code>--device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri:/dev/dri/card0 --device /dev/kfd:/dev/kfd</code></pre>
<h3>For Intel GPUs & iGPUs</h3>
<p>The Followings have to be added in docker-compose file/docker-cli cm respectively</p>
<p><strong>docker compose</strong></p>
<pre><code>devices:
    - /dev/dri/renderD128:/dev/dri/renderD128
    - /dev/dri/card0:/dev/dri/card0</code></pre>
<p><strong>docker cli</strong></p>
<pre><code>--device /dev/dri/renderD128:/dev/dri/renderD128 --device /dev/dri/card0:/dev/dri/card0</code></pre>
<h4>DISCLAIMER: Jellyfin FFMPEG and corresponding ideas were used in this image to enable the HW-Acceleration</h4>
<h2>Parameters</h2>
<p>Container images are configured using parameters passed at runtime (such as those above). These parameters are separated by a colon and indicate <code>&lt;external&gt;:&lt;internal&gt;</code> respectively. For example, <code>-p 8090:80</code> would expose port <code>80</code> from inside the container to be accessible from the host's IP on port <code>8090</code> outside the container. </p>
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
      <td>Location of Survaillance Recordings on disk.</td>
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
uid=1000(dockeruser) gid=1000(dockergroup) groups=1000(dockergroup)</code></pre>
<h2>For iSpy Agent DVR specific userguide visit:</h2>
<a href="https://www.ispyconnect.com/userguide-agent-dvr.aspx" rel="nofollow noopener">https://www.ispyconnect.com/userguide-agent-dvr.aspx</a>
</p>
<h2>Non host network use:</h2>
<p> To useNon host network, you will need to open up ports for this to porperly work, thus the UDP ports listed in the sample runs.</p>
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
<p>
  <strong>Note:</strong> You can use <a href="https://containrrr.dev/watchtower/" rel="nofollow noopener">Watchtower</a> as a solution to automated updates of existing Docker containers. But it is discouraged to use automated updates. However, this is a useful tool for one-time manual updates of containers where you have forgotten the original parameters. In the long term, it is recommend to use <a href="https://itnext.io/a-beginners-guide-to-deploying-a-docker-application-to-production-using-docker-compose-de1feccd2893" rel="nofollow noopener">Docker Compose</a>.
</p>
<h3>Image Update Notifications - Diun (Docker Image Update Notifier)</h3>
<ul>
  <li>You can also use <a href="https://crazymax.dev/diun/" rel="nofollow noopener">Diun</a> for update notifications. Other tools that automatically update containers unattended are not encouraged </li>
</ul>
<h2>Migration Notes:</h2>
<h4>If you had the old format of audio and video volumes please move them within the new media folder before starting the container again.</h4>
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
<p><strong> - ARM SBCs: </strong>In the case of Raspberry Pi (Only 4 and newer can have GPU acceleration if v4l2 Encode/Decode is enabled, which is Disabled by default in RaspiOS and very trick to enable. Personally I haven't been able to enable this till now). Also the performance of Encode/Decode on ARM is somewhat not usable. If you have a HIGH END SBC then you may research a way to pass your relative Render device and get VAAPI working. Personally I don't posses a HIGH END ARM SBC. So I am unable to provide any instruction. If anyone gets success please let me know via Github. Rest assured, I will include that instruction and will give you proper credit in the github.</p>
<p><strong> - Things to make sure before Submitting a issue:</strong> </p>
  <ul>
    <li>Update your <strong>Docker Engine</strong> to the latest available, specially on OSX. After updating docker engine please check if the issue has been resolved.
    </li>
    <li>Inspect the <code>AgentDVR-IP:AGENTDVR_WEBUI_PORT/logs.html</code> for Error list
    </li>
    <li>If you intending to run this image on Raspberry Pi 5 then use <strong>Ubuntu or Ubuntu Server</strong> as your OS. There is a bug in debian which fataly effects the execution of AgentDVR and many other applications that are written on .Net Core. Other Raspberry Pi doesn't have this issue at the time of writing this.
    </li>
    <li>Make sure to have you have access to your Docker Compose File/Docker CLI command which was used to deploy your container and Logs from <code>logs.html</code> include those to your github issue/reddit post.
    </li>
  </ul>

<p><strong> - Major Changes</strong></p>
<ul>
<li><strong>5.8.1.0:</strong> - FFMPEG version bumped from 6.0.1 to 7.0.2</li> 
<li><strong>5.8.1.0:</strong> - DOTNET version bumped to 9.0</li>
<li><strong>5.8.1.0:</strong> - Environment Variable WEBUI_PORT is now changed to AGENTDVR_WEBUI_PORT. Those who use Environment Variable to change the Port for Web UI, please use AGENTDVR_WEBUI_PORT from now on.</li>
<li><strong>5.8.1.0:</strong> - <code>mekayelank/ispyagentdvr</code> image is now fully backword compatible with <code>doitandbedone/ispyagentdvr</code> image. From now on, you don't have to change the directory mapping to switch from <code>doitandbedone/ispyagentdvr</code> to <code>mekayelank/ispyagentdvr</code></li>
<li><strong>5.8.1.0:</strong> - TURN Server Port range changed from 50000-50010 to 50000-50100. Please set the range in Docker CLI or Docker Compose to 50000-50100</li>
<li><strong>5.3.5.0:</strong> - Fixed HW-Accelerated Encode/Decode for AMD, Nvidia & Intel GPUs (From v5.3.5.0 GPU Accelerated Encode/Decode is Tested WORKING in x86_64 but improvements maybe needed. Please submit issues in github, if one faces any.)</li> 
<li><strong>5.2.8.0 :</strong> - (BETA) Added HW-Acceleration for Nvidia, AMD & Intel GPUs & iGPUs (in x86_64). Also added HW-Acceleration for Raspberry Pi 4 and beyond. Related configs may need to be added to the /boot/config.txt</li> 
<li><strong>4.8.2.0:</strong> - Fixed ARMHF dependency issues and other improvements.</li> 
<li><strong>4.8.0.0:</strong> - Major Bug fixes with ONVIF fix</li> 
<li><strong>4.7.4.0:</strong> <ul> <li> Fixed bump FFmpeg 6 version that was crashing on missing GPU drivers</li>  <li> Add TURN server option to local server settings.</li></ul>
</li>
<li><strong>4.7.3.0:</strong> - Bumped FFmpeg version from 5 to 6.</li>
<li><strong>4.1.2.0:</strong> - Initial Release.</li>
</ul>

<h2>Issues & Requests</h2>
<p> To submit this Docker image specific issues or requests visit this docker image's Github Link: <a href="https://www.github.com/MekayelAnik/ispyagentdvr-docker" rel="nofollow noopener">https://www.github.com/MekayelAnik/ispyagentdvr-docker</a>
</p>
<p> For iSpy AgentDVR related issues and requests, please visit: <a href="https://www.reddit.com/r/ispyconnect/" rel="nofollow noopener">https://www.reddit.com/r/ispyconnect/</a>
</p>
