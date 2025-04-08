#!/bin/bash
echo "Force restarting WireGuard and fixing routing..."
docker exec wireguard wg-quick down wg0 || true
sleep 2
docker exec wireguard wg-quick up wg0
sleep 2
docker exec wireguard /config/wireguard-routing.sh
sleep 1
docker exec wireguard /config/setup-proxy.sh
echo "Done. Check status with ./debug-proxy.sh"
