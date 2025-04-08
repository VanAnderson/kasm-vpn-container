#!/bin/bash
echo "[$(date)] DIRECT SETUP: Force-installing TinyProxy..."
apk update && apk add --no-cache tinyproxy curl bind-tools

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

# Start TinyProxy directly
echo "[$(date)] DIRECT SETUP: Starting TinyProxy..."
/usr/bin/tinyproxy -d -c /etc/tinyproxy/tinyproxy.conf &

echo "[$(date)] DIRECT SETUP: Done. Verify status with:"
echo "pgrep tinyproxy"
echo "netstat -tulpn | grep 8888"
