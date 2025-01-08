#!/bin/bash
## SPDX-License-Identifier: MIT
## 2024 Starry Wang <hxstarrys@gmail.com> + 2024 Andrea Salvatori <16443598+Sonic0@users.noreply.github.com>
# Description: This script is used to automatically reconnect WireGuard VPN when the connection is lost.
set -euo pipefail

WG_INTERFACE="wg0"
DESTINATION=${DESTINATION:-"<your_connection_destination_ip_or_domain>"}
DESTINATION_VPN_IP=${WG_SERVER_IP:-"10.8.0.1"} # WireGuard server IP. It is the WireGuard server's IP address in the VPN network

check_wireguard_connection() {
    # Check if the interface exists
    if ip link show "$WG_INTERFACE" > /dev/null 2>&1; then
        # Check if there's an active handshake
        if wg show "$WG_INTERFACE" | grep -q 'latest handshake'; then
            echo "WireGuard is connected."
            return 0
        else
            echo "WireGuard interface is up but not connected."
            return 1
        fi
    else
        echo "WireGuard interface is not found."
        return 1
    fi
}

restart_wireguard() {
	echo "Restart WireGuard interface ${WG_INTERFACE}"
	wg-quick down ${WG_INTERFACE} || echo -n
	sleep 5
	wg-quick up ${WG_INTERFACE}
	if [ $? -eq 0 ]; then
		echo "WireGuard started successfully."
	else
		echo "Failed to start WireGuard."
	fi
}

#------- Main script logic --------#
echo "Start detecting connection on $DESTINATION"
if ! check_wireguard_connection; then
    restart_wireguard || exit 1
fi

i=0
while [[ $i -lt 5 ]] ; do
	{
	ping -c 5 -i 5 -W 5 "${DESTINATION}" > /dev/null && ping -c 5 -i 5 -W 5 "${DESTINATION_VPN_IP}" > /dev/null && check_wireguard_connection && i=0
	} || {
	(( i += 1 ))
	echo "$i: ping ${DESTINATION} timeout"
	}
done

restart_wireguard
