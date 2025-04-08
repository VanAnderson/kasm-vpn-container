#!/bin/bash

# Directory to store wireguard configuration
WG_CONF_DIR="/config/wg_confs"
WG_CONFIG_FILE="${WG_CONF_DIR}/wg0.conf"
WG_CONFIG_HASH_FILE="/config/.wg_config_hash"

echo "[$(date)] Checking for Wireguard configuration changes..."

# Create directory if it doesn't exist
mkdir -p "${WG_CONF_DIR}"

# Check if WIREGUARD_CONFIG environment variable is set
if [ -z "${WIREGUARD_CONFIG}" ]; then
    echo "[$(date)] No WIREGUARD_CONFIG provided, using existing configuration"
    # If config file doesn't exist, create a placeholder to alert user
    if [ ! -f "${WG_CONFIG_FILE}" ]; then
        echo "[$(date)] WARNING: No Wireguard configuration found. Please set WIREGUARD_CONFIG environment variable."
        echo "# Please set WIREGUARD_CONFIG environment variable to your Wireguard configuration" > "${WG_CONFIG_FILE}"
    fi
else
    # Remove any surrounding quotes and empty lines that might cause parsing issues
    CLEANED_CONFIG=$(echo "${WIREGUARD_CONFIG}" | sed 's/^"//;s/"$//' | grep -v '^$')
    
    # Calculate hash of current environment config
    CURRENT_HASH=$(echo "${CLEANED_CONFIG}" | sha256sum | awk '{print $1}')
    
    # Check if hash file exists
    if [ -f "${WG_CONFIG_HASH_FILE}" ]; then
        STORED_HASH=$(cat "${WG_CONFIG_HASH_FILE}")
    else
        STORED_HASH=""
    fi
    
    # If hashes are different or no previous hash exists, update config
    if [ "${CURRENT_HASH}" != "${STORED_HASH}" ]; then
        echo "[$(date)] Wireguard configuration changed, updating..."
        
        # Backup old config if it exists
        if [ -f "${WG_CONFIG_FILE}" ]; then
            cp "${WG_CONFIG_FILE}" "${WG_CONFIG_FILE}.backup"
        fi
        
        # Save new config
        echo "${CLEANED_CONFIG}" > "${WG_CONFIG_FILE}"
        
        # Update stored hash
        echo "${CURRENT_HASH}" > "${WG_CONFIG_HASH_FILE}"
        
        # Set proper permissions
        chmod 600 "${WG_CONFIG_FILE}"
        
        echo "[$(date)] Wireguard configuration updated successfully"
        
        echo "[$(date)] Restarting WireGuard due to configuration change..."
        # Bring down interface if it exists
        wg-quick down wg0 2>/dev/null || true
        sleep 2
        # Bring up with new configuration
        if wg-quick up wg0; then
            echo "[$(date)] WireGuard service started successfully."
        else
            echo "[$(date)] ERROR: Failed to start WireGuard service. Check configuration."
        fi
    else
        echo "[$(date)] No changes to Wireguard configuration"
        # Check if WireGuard is running, if not try to start it
        if ! wg show >/dev/null 2>&1; then
            echo "[$(date)] WireGuard not running, attempting to start..."
            if wg-quick up wg0; then
                echo "[$(date)] WireGuard service started."
            else
                echo "[$(date)] ERROR: Failed to start WireGuard service. Check configuration."
            fi
        fi
    fi
fi
