#!/bin/bash

# Adding Non-free Sources
  echo "Types: deb" >> /etc/apt/sources.list.d/debian.sources
  echo "URIs: http://deb.debian.org/debian" >> /etc/apt/sources.list.d/debian.sources
  echo "Suites: bookworm bookworm-updates" >> /etc/apt/sources.list.d/debian.sources
  echo "Components: non-free" >> /etc/apt/sources.list.d/debian.sources
  echo "Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" >> /etc/apt/sources.list.d/debian.sources

# Adding UNSTABLE Sources
  echo "Types: deb" >> /etc/apt/sources.list.d/debian.sources
  echo "URIs: http://deb.debian.org/debian" >> /etc/apt/sources.list.d/debian.sources
  echo "Suites: unstable" >> /etc/apt/sources.list.d/debian.sources
  echo "Components: main" >> /etc/apt/sources.list.d/debian.sources
  echo "Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" >> /etc/apt/sources.list.d/debian.sources

# Adding EXPERIMENTAL Sources
  touch /etc/apt/sources.list.d/experimental.list
  echo "deb http://deb.debian.org/debian experimental main" >> /etc/apt/sources.list.d/experimental.list

# APT Update
  apt-get update

# Install One SPECIFIC dependency for FFmpeg6 deb
  apt-get satisfy "libjxl0.7 (>= 0.7.0)" -y --no-install-recommends

# Install FFmpeg6 deb
  apt-get -t experimental install ffmpeg -y --no-install-recommends

# Important for ARMHF
arch=$(uname -m)
case $(arch) in
		'arm' | 'armv6l' | 'armv7l')

			# The follwing is MUST!
			apt-get install -y libatlas-base-dev libatlas3-base  --no-install-recommends
			# The Following is OPTIONAL but recommanded
			apt-get -t experimental install -y glibc-source --no-install-recommends
#                       apt-get install -y coturn
		;;
	esac
exit 0
