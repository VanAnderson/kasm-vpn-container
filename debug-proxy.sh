#!/bin/bash
echo "=== TinyProxy Debug Info ==="
echo "1. Process status:"
docker exec wireguard pgrep tinyproxy || echo "Not running"
docker exec wireguard bash -c "pgrep tinyproxy >/dev/null && echo 'TinyProxy is running' || echo 'TinyProxy is NOT running'"

echo "2. Network status:"
docker exec wireguard netstat -tulpn | grep 8888 || echo "No proxy port detected"

echo "3. Container IPs:"
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{"\n"}}{{end}}' wireguard
docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{"\n"}}{{end}}' kasm_firefox

echo "4. Container status:"
docker ps | grep -E "wireguard|kasm"

echo "5. Container logs:"
docker logs --tail 50 wireguard

echo "6. Cron status:"
docker exec wireguard pgrep crond || echo "Cron not running"
docker exec wireguard bash -c "pgrep crond >/dev/null && echo 'Cron daemon is running' || echo 'Cron daemon is NOT running'"
docker exec wireguard crontab -l

echo "7. Boot logs:"
docker exec wireguard cat /config/tinyproxy-boot.log

echo "8. WireGuard status:"
docker exec wireguard wg
docker exec wireguard ip addr show wg0 || echo "WireGuard interface not found"
docker exec wireguard bash -c "ping -c 1 -I wg0 8.8.8.8 >/dev/null 2>&1 && echo 'WireGuard routing is WORKING' || echo 'WireGuard routing is NOT WORKING'"

echo "9. DNS status:"
docker exec wireguard cat /etc/resolv.conf
docker exec wireguard bash -c "nslookup google.com >/dev/null 2>&1 && echo 'DNS resolution WORKING' || echo 'DNS resolution FAILED'"

echo "10. Manual test:"
docker exec wireguard apk update
docker exec wireguard curl -v --proxy 127.0.0.1:8888 https://www.google.com

echo "11. Setup Instructions:"
cat << SETUPINST
# Kasm Firefox with WireGuard VPN

## Container Setup Instructions

### Proxy Configuration for Firefox

1. Connect to Kasm at: https://localhost:6901
2. Password: your_secure_password
3. MANUALLY configure Firefox proxy settings:
   - Open Firefox preferences
   - Go to General → Network Settings
   - Select 'Manual proxy configuration'
   - Set HTTP Proxy to: $(docker inspect -f '{{range .NetworkSettings.Networks}}{{.IPAddress}}{{"\n"}}{{end}}' wireguard | head -1) and Port: 8888
   - Check 'Also use this proxy for HTTPS'
   - Check 'Use this proxy server for all protocols'
4. Test by going to: https://ipleak.net

### Troubleshooting

If proxy issues occur:
- Run: ./restart-proxy.sh to restart the proxy
- Run: ./force-vpn.sh to fix WireGuard routing issues
- Run: ./force-proxy.sh if restart doesn't work
- Run: ./debug-proxy.sh for detailed diagnostic information

### WireGuard Configuration

- Set WIREGUARD_CONFIG environment variable in Unraid Docker settings
- When this variable is changed, container will restart and apply the new config
- The WireGuard service will be automatically restarted when configuration changes
SETUPINST
echo "=== Debug complete ==="
