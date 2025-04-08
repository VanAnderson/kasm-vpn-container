#!/bin/bash

echo "[$(date)] Running TinyProxy setup..."

# First check if WireGuard is running and routing properly
if ! ping -c 1 -W 3 -I wg0 8.8.8.8 >/dev/null 2>&1; then
    echo "[$(date)] WARNING: WireGuard routing test failed, attempting to fix..."
    /config/wireguard-routing.sh
    sleep 2
fi

# Install TinyProxy if not installed
if ! command -v tinyproxy &> /dev/null; then
    echo "[$(date)] Installing TinyProxy..."
    apk update && apk add --no-cache tinyproxy curl bind-tools
fi

# Create TinyProxy config
mkdir -p /etc/tinyproxy
cat > /etc/tinyproxy/tinyproxy.conf << PROXYCONF
User nobody
Group nobody
Port 8888
Listen 0.0.0.0
Timeout 600
Allow 0.0.0.0/0
ConnectPort 80
ConnectPort 443
ConnectPort 8080
FilterDefaultDeny No
LogLevel Info
PROXYCONF

# Kill any existing TinyProxy processes
pkill tinyproxy 2>/dev/null || true
sleep 1

# Start TinyProxy in the background
echo "[$(date)] Starting TinyProxy daemon..."
/usr/bin/tinyproxy -d -c /etc/tinyproxy/tinyproxy.conf &

# Get the container's IP address
CONTAINER_IP=$(hostname -i | awk '{print $1}')

# Verify it's running
sleep 2
if pgrep tinyproxy >/dev/null; then
    echo "[$(date)] TinyProxy started successfully"
    netstat -tulpn | grep 8888
    
    # Test proxy connectivity
    if curl -s --connect-timeout 5 --proxy http://127.0.0.1:8888 http://www.google.com >/dev/null; then
        echo "[$(date)] Proxy connectivity test PASSED"
    else
        echo "[$(date)] Proxy connectivity test FAILED - this might indicate routing issues"
    fi
    
    # Display proxy configuration
    echo ""
    echo "========================================================================="
    echo "PROXY CONFIGURATION INFO:"
    echo " - Proxy Server: ${CONTAINER_IP}"
    echo " - Proxy Port: 8888"
    echo " - WireGuard IP: $(curl -s --interface wg0 https://ifconfig.me 2>/dev/null || echo "Unknown")"
    echo "========================================================================="
    echo ""
else
    echo "[$(date)] Failed to start TinyProxy"
fi
