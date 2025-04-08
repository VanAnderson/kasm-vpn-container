#!/bin/bash
echo "Directly starting TinyProxy (bypassing all container init)..."
docker exec wireguard /config/direct-setup.sh
echo "Checking TinyProxy status:"
docker exec wireguard pgrep tinyproxy && echo "TinyProxy is running" || echo "TinyProxy is NOT running"
docker exec wireguard netstat -tulpn | grep 8888 || echo "TinyProxy not listening on port 8888"
