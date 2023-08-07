#!/bin/bash
echo "Types: deb" >> /etc/apt/sources.list.d/debian.sources
echo "URIs: http://deb.debian.org/debian" >> /etc/apt/sources.list.d/debian.sources
echo "Suites: bookworm bookworm-updates" >> /etc/apt/sources.list.d/debian.sources
echo "Components: non-free" >> /etc/apt/sources.list.d/debian.sources
echo "Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" >> /etc/apt/sources.list.d/debian.sources

echo "Types: deb" >> /etc/apt/sources.list.d/debian.sources
echo "URIs: http://deb.debian.org/debian" >> /etc/apt/sources.list.d/debian.sources
echo "Suites: unstable" >> /etc/apt/sources.list.d/debian.sources
echo "Components: main" >> /etc/apt/sources.list.d/debian.sources
echo "Signed-By: /usr/share/keyrings/debian-archive-keyring.gpg" >> /etc/apt/sources.list.d/debian.sources

touch /etc/apt/sources.list.d/experimental.list
echo "deb http://deb.debian.org/debian experimental main" >> /etc/apt/sources.list.d/experimental.list

exit 0
