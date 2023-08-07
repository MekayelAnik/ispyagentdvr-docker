#!/bin/bash
	apt-get update && apt-get upgrade -y
	apt-get install -y curl unzip wget
	apt-get install -y tzdata alsa-utils libgdiplus --no-install-recommends
exit 0
