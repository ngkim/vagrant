#!/bin/bash

echo "1. configure apt-get proxy"
CACHE_SERVER="211.224.204.145:23142"
sudo cat > /etc/apt/apt.conf.d/02proxy <<EOF
Acquire::http { Proxy "http://$CACHE_SERVER"; };
EOF

echo "2. apt-get update"
sudo apt-get update


