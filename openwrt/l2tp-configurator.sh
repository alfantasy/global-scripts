#!/bin/sh
# l2tp-configurator.sh
# Interactive configurator for L2TP/IPSec on OpenWRT (BusyBox-friendly)
# Create templates for: strongswan (psk), /etc/xl2tpd/xl2tpd.conf, /etc/ppp/options.l2tpd.client, /etc/l2tp-ipsec-manager.conf (optional, when using l2tp-ipsec-manager.sh)
# /etc/ipsec.conf (with tunnel IPSec)
# Also creates a helper modem-info script, compile autorun script for refresh NAT-Configuration before ATM-connection
# NOTE: run as root.

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;37m[i] Script must be run as root.\033[0m" 1>&2
    echo -e "\033[1;34m[i] Please run the script with sudo or log in as root and try again.\033[0m" 1>&2
    exit 1
fi

case "$1" in
    --start)
        echo -e "\033[1;37m[i] Starting L2TP/IPSec configurator...\033[0m"
        