#!/bin/bash

# Check if WireGuard interface exists
if ! ip link show wg0 >/dev/null 2>&1; then
    echo "[$(date)] ERROR: WireGuard interface not found"
    exit 1
fi

echo "[$(date)] Checking and fixing WireGuard routing..."

# Ensure forwarding is enabled
echo 1 > /proc/sys/net/ipv4/ip_forward

# Get the DNS servers from the WireGuard config
WG_DNS=$(grep "DNS" /config/wg_confs/wg0.conf | cut -d= -f2- | tr -d ' ')

# If DNS is provided in the WireGuard config, use it
if [ -n "$WG_DNS" ]; then
    echo "[$(date)] Using DNS from WireGuard config: ${WG_DNS}"
    
    # Create resolv.conf that will use the VPN DNS
    echo "nameserver ${WG_DNS}" > /etc/resolv.conf
else
    echo "[$(date)] WARNING: No DNS specified in WireGuard config, using fallback DNS"
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

# Test connectivity through WireGuard
echo "[$(date)] Testing WireGuard connectivity..."
if ping -c 3 -W 5 -I wg0 8.8.8.8 >/dev/null 2>&1; then
    echo "[$(date)] WireGuard interface is connected and routing properly."
else
    echo "[$(date)] WARNING: WireGuard interface does not appear to be routing traffic correctly!"
fi

# Test DNS resolution
echo "[$(date)] Testing DNS resolution..."
if nslookup google.com >/dev/null 2>&1; then
    echo "[$(date)] DNS resolution is working."
else
    echo "[$(date)] WARNING: DNS resolution failed. Trying fallback DNS servers..."
    # Try to set fallback DNS servers
    echo "nameserver 1.1.1.1" > /etc/resolv.conf
    echo "nameserver 8.8.8.8" >> /etc/resolv.conf
fi

echo "[$(date)] WireGuard routing setup complete."
