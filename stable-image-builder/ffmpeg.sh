#!/bin/bash
apt-get satisfy "libjxl0.7 (>= 0.7.0)" -y --no-install-recommends
apt-get -t experimental install ffmpeg -y --no-install-recommends
exit 0
