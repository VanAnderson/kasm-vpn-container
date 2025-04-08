#!/bin/bash

# Apply Wireguard configuration first
/config/wireguard-config.sh

# Wait a moment for WireGuard to initialize
sleep 3

# Fix WireGuard routing
/config/wireguard-routing.sh

# Execute our TinyProxy setup script
echo "[ENTRYPOINT] Starting TinyProxy before container init..."
/config/setup-proxy.sh > /config/tinyproxy-boot.log 2>&1

# Set up cron to check for TinyProxy every minute
echo "* * * * * /config/setup-proxy.sh > /config/tinyproxy-cron.log 2>&1" > /tmp/tinyproxy-cron
# Add hourly check for WireGuard routing
echo "0 * * * * /config/wireguard-routing.sh > /config/routing-check.log 2>&1" >> /tmp/tinyproxy-cron
crontab /tmp/tinyproxy-cron
rm -f /tmp/tinyproxy-cron

# Start cron daemon
crond

# Get the container's IP address
CONTAINER_IP=$(hostname -i | awk '{print $1}')

# Get WireGuard external IP (if available)
WG_IP=$(curl -s --interface wg0 https://ifconfig.me 2>/dev/null || echo "Unknown")

# Display Firefox proxy configuration instructions
cat << EOFBLOCK

========================================================================
FIREFOX PROXY CONFIGURATION INSTRUCTIONS
========================================================================

To configure Firefox in your Kasm container to use this WireGuard proxy:

1. Open Firefox in the Kasm container (http://YOUR_SERVER_IP:6901)

2. Go to Firefox Settings:
   - Click the menu button (≡) in the top-right corner
   - Select "Settings"

3. Scroll down to "Network Settings" and click "Settings..."

4. Select "Manual proxy configuration"

5. Enter the following settings:
   - HTTP Proxy: ${CONTAINER_IP}
   - Port: 8888
   - Check "Also use this proxy for HTTPS"
   - No Proxy for: localhost, 127.0.0.1
   
6. Click "OK" to save settings

7. Verify your connection by visiting a site like https://whatismyipaddress.com

Status Information:
------------------
WireGuard Interface: $(ip link show wg0 >/dev/null 2>&1 && echo "UP" || echo "DOWN")
WireGuard IP: ${WG_IP}
Internet Routing: $(ping -c 1 -W 3 -I wg0 8.8.8.8 >/dev/null 2>&1 && echo "WORKING" || echo "FAILED")
DNS Resolution: $(nslookup google.com >/dev/null 2>&1 && echo "WORKING" || echo "FAILED")
TinyProxy Status: $(pgrep tinyproxy >/dev/null 2>&1 && echo "RUNNING" || echo "NOT RUNNING")

========================================================================

EOFBLOCK

# Now continue with the original entrypoint
echo "[ENTRYPOINT] Continuing with container init..."
exec /init
