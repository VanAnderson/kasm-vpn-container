#!/bin/bash
echo "Restarting TinyProxy..."
docker exec wireguard /config/setup-proxy.sh
echo "Checking TinyProxy logs:"
docker exec wireguard cat /config/tinyproxy-boot.log 2>/dev/null || echo "No boot log found"
docker exec wireguard cat /config/tinyproxy-cron.log 2>/dev/null || echo "No cron log found"
