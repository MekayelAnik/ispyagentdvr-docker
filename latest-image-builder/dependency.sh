#!/bin/bash
	apt-get -o Acquire::Check-Valid-Until=false -o Acquire::Check-Date=false update
	apt-get upgrade -y
	apt-get install -y curl unzip wget
	apt-get install -y tzdata alsa-utils libgdiplus --no-install-recommends
exit 0
