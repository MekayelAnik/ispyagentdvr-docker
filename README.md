# ispyagentdvr-docker
Multi Aarch image of iSpy's Agent DVR, standalone free-to-use NVR software for IP Camera management

<h1>iSpy Agent DVR multi-arch image</h1>
<img alt="ispyagentdvr" src="https://ispycontent.azureedge.net/img/ispy2.png">
<p>This is an unofficial multi-aarch docker image of Agent DVR of iSpy created for multiplatform support. iSpy Agent DVR creates a local server for IP cameras to be managed. Official Website: <a href="https://www.ispyconnect.com" rel="nofollow noopener">https://www.ispyconnect.com</a>
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
<h2>Anouncements:</h2>
<p> -  Please download images for Status: <strong>Tested "WORKING"</strong> platforms only.</p>
<p> - Alhamdulillah, The <strong>ARMHF</strong> image has been fixed. Thanks To <strong> Sean T</strong> for fixing the issues</p>
<p> - For <strong>ARM32-bit/ARMHF</strong> devices, please download image version greater or equal to <strong>4.8.2.0</strong>. From now on <strong>ARMHF</strong> is <strong>TESTED-OK </strong></p>
<h2>Version Tags</h2>
<p>This image provides various versions that are available via tags. Please read the <a href="https://www.ispyconnect.com/producthistory.aspx?productid=27" rel="nofollow noopener">update information</a> carefully and exercise caution when using "older versions" tags as they tend to contain unfixed bugs. </p>
<table>
  <thead>
    <tr>
      <th align="center">Tag</th>
      <th align="center">Available</th>
      <th>Description</th>
    </tr>
  </thead>
  <tbody>
    <tr>
      <td align="center">latest</td>
      <td align="center">✅</td>
      <td>Stable "iSpy Agent DVR" releases</td>
    </tr>
    <tr>
      <td align="center">4.9.6.0</td>
      <td align="center">✅</td>
      <td>Static "iSpy Agent DVR" build version 4.9.6.0</td>
    </tr>
  </tbody>
</table>
<h2>Running Image :</h2>
<p>Here are some example snippets to help you get started creating a container.</p>
<h3>docker-compose (recommended, <a href="https://itnext.io/a-beginners-guide-to-deploying-a-docker-application-to-production-using-docker-compose-de1feccd2893" rel="nofollow noopener">click here for more info</a>) </h3>
<pre><code>---
version: "3.9"
services:
  ispyagentdvr:
    image: mekayelanik/ispyagentdvr:latest
    container_name: ispyagentdvr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Dhaka
    volumes:
      - /path/to/config:/AgentDVR/Media/XML
      - /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50010:50000-50010/udp
    restart: unless-stopped
</code></pre>

<strong>Note:</strong> In the case of Raspberry Pi and other low power ARM SBCs, please hit the WebUI URL atleast 30 seconds after the container deployment. A few seconds maybe required by the ARM processors to kick start the needed services. Before this time you may not get response in the web browser. Also at the first time, you may have to refresh the WebUI a couple of times for the UI to get fully loaded.

<h3>docker cli ( <a href="https://docs.docker.com/engine/reference/commandline/cli/" rel="nofollow noopener">click here for more info</a>) </h3>
<pre><code>docker run -d \
  --name=ispyagentdvr \
  -e PUID=1000 \
  -e PGID=1000 \
  -e TZ=Asia/Dhaka \
  -p 8090:8090 \
  -p 3478:3478/udp \
  -p 50000-50010:50000-50010/udp \
  -v /path/to/config:/AgentDVR/Media/XML \
  -v /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media \
  -v /path/to/commands:/AgentDVR/Commands \
  --restart unless-stopped \
  mekayelanik/ispyagentdvr:latest
</code></pre>
<h3>If anyone wishes to give dedicated Local IP to iSpy Agent DVR container using MACVLAN ( <a href="https://docs.docker.com/network/macvlan/" rel="nofollow noopener">click here for more info</a>) </h3>
<pre><code>---
version: "3.9"
services:
  ispyagentdvr:
    image: mekayelanik/ispyagentdvr:latest
    container_name: ispyagentdvr
    environment:
      - PUID=1000
      - PGID=1000
      - TZ=Asia/Dhaka
    volumes:
      - /path/to/config:/AgentDVR/Media/XML
      - /path/to/recordings:/AgentDVR/Media/WebServerRoot/Media
      - /path/to/commands:/AgentDVR/Commands
    ports:
      - 8090:8090
      - 3478:3478/udp
      - 50000-50010:50000-50010/udp
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
    driver: macvlan
    driver_opts:
      parent: eth0
    ipam:
      config:
        - subnet: "192.168.0.0/16"
          ip_range: "192.168.2.1/24"
          gateway: "192.168.1.1"</code></pre>
<p>In oreder to macvlan work properly, you must map any valid MAC address to <code>mac_address:</code>. Also you muat map any valid IP address in your <code>ip_range</code> to <code>ipv4_address:</code>.This will be your containr's IP. Then you must map your Router's Local IP Subnet to <code>subnet:</code> After that you must map your Desired Local IP range within the subnet to <code>ip_range:</code> Finally you must map your Router's LAN IP Address <code>gateway:</code>
</p>
<p>In the case of MACVLAN, you must access the WebUI using <code>http://ipv4_address:8090</code>
</p>
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
      <td>WebUI</td>
    </tr>
    <tr>
      <td align="center">
        <code>-p 3478/udp</code>
      </td>
      <td>Main port used for TURN server communication</td>
    </tr>
    <tr>
      <td align="center">
        <code>-p 50000-50010//udp</code>
      </td>
      <td>Ports used to create connections or WebRTC. These will be used as needed</td>
    </tr>
    <tr>
      <td align="center">
        <code>-e PUID=1000</code>
      </td>
      <td>for UserID - see below for explanation</td>
    </tr>
    <tr>
      <td align="center">
        <code>-e PGID=1000</code>
      </td>
      <td>for GroupID - see below for explanation</td>
    </tr>
    <tr>
      <td align="center">
        <code>-e TZ=Asia/Dhaka</code>
      </td>
      <td>specify a timezone to use, see this <a href="https://en.wikipedia.org/wiki/List_of_tz_database_time_zones#List" rel="nofollow noopener">list</a>. </td>
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
      <li>or update a single image: <code>docker compose pull ispydvragent</code>
      </li>
    </ul>
  </li>
  <li>Let compose update all containers as necessary: <code>docker compose up -d</code>
    <ul>
      <li>or update a single container (recommended): <code>docker compose up -d ispydvragent</code>
      </li>
    </ul>
  </li>
  <li>To remove the old unused images run: <code>docker image prune</code>
  </li>
</ul>
<h3>Via Docker Run</h3>
<ul>
  <li>Update the image: <code>docker pull mekayelanik/ispydvragent:latest</code>
  </li>
  <li>Stop the running container: <code>docker stop ispydvragent</code>
  </li>
  <li>Delete the container: <code>docker rm ispydvragent</code>
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
--run-once ispydvragent</code></pre>
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

<h2>Versions</h2>
<ul>
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