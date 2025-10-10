#!/bin/sh
# l2tp-configurator.sh
# Interactive configurator for L2TP/IPSec on OpenWRT (BusyBox-friendly)
# Create templates for: strongswan (psk), /etc/xl2tpd/xl2tpd.conf, /etc/ppp/options.l2tpd.client, /etc/l2tp-ipsec-manager.conf (optional, when using l2tp-ipsec-manager.sh)
# /etc/ipsec.conf (with tunnel IPSec)
# Also creates a helper modem-info script, compile autorun script for refresh NAT-Configuration before ATM-connection
# NOTE: run as root.

LDEFAULT=$(echo $LANG > /dev/null 2>&1 || cut -c1-2)
LOG_FILE="/var/log/l2tp-configurator.log"

# Logging to /var/log/l2tp-configurator.log
log() {
    echo -e "[$(date '+%Y-%m-%d %H:%M:%S')] $*" >> "$LOG_FILE"
}

if [ "$(id -u)" != "0" ]; then
    echo -e "\033[1;37m[i] Script must be run as root.\033[0m" 1>&2
    echo -e "\033[1;34m[i] Please run the script with sudo or log in as root and try again.\033[0m" 1>&2
    exit 1
fi

start_only_configurator() {
    mkdir -p /etc/xl2tpd
    mkdir -p /etc/ppp

    echo -e "\033[1;37m[i] Configuring special file /etc/xl2tpd/xl2tpd.conf...\033[0m"
    read -p "Enter the IP address of the server: " SERVER_IP
    read -p "Enter the IP address of the client: " CLIENT_IP
    read -p "Enter the port number for L2TP: " L2TP_PORT
    read -p "Enter the name tunnel for L2TP: " TUNNEL_NAME

    echo -e "\033[1;37m[d] IP address of the server: $SERVER_IP\033[0m"
    echo -e "\033[1;37m[d] IP address of the client: $CLIENT_IP\033[0m"
    echo -e "\033[1;37m[d] Port number for L2TP: $L2TP_PORT\033[0m"
    echo -e "\033[1;37m[d] Name tunnel for L2TP: $TUNNEL_NAME\033[0m"

    read -p "Use debug-functions? (y/n): " REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DEBUG=1
    else
        DEBUG=0
    fi

    read -p "Enter the count reconnections: " RECONNECT_COUNT    

    echo -e "\033[1;37m[d] Use debug-functions: $DEBUG\033[0m"
    echo -e "\033[1;37m[d] Count reconnections: $RECONNECT_COUNT\033[0m"

    echo -e "\033[1;37m[i] Creating special file /etc/xl2tpd/xl2tpd.conf...\033[0m"

    if [ $DEBUG = 1 ]; then
        cat << EOF > /etc/xl2tpd/xl2tpd.conf
# /etc/xl2tpd/xl2tpd.conf

[global]
port = $L2TP_PORT
access control = no

[lac $TUNNEL_NAME]
lns = $SERVER_IP
ppp debug = yes
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
redial = yes
redial timeout = 5
max redials = $RECONNECT_COUNT
require chap = yes
require authentication = yes
EOF
    else
        cat << EOF > /etc/xl2tpd/xl2tpd.conf
# /etc/xl2tpd/xl2tpd.conf

[global]
port = $L2TP_PORT
access control = no

[lac $TUNNEL_NAME]
lns = $SERVER_IP
ppp debug = no
pppoptfile = /etc/ppp/options.l2tpd.client
length bit = yes
redial = yes
redial timeout = 5
max redials = $RECONNECT_COUNT
require chap = yes
require authentication = yes
EOF
    fi

    echo -e "\033[1;32m✅ Special file /etc/xl2tpd/xl2tpd.conf created successfully.\033[0m"
    echo -e "\033[1;37m[i] Configuring special file /etc/ppp/options.l2tpd.client...\033[0m"

    read -p "Enter the username for L2TP: " L2TP_USERNAME
    read -p "Enter the password for L2TP: " L2TP_PASSWORD

    read -p "Use debug functions? (y/n): " REPLY
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        DEBUG=1
    else
        DEBUG=0
    fi

    echo -e "\033[1;37m[d] Username for L2TP: $L2TP_USERNAME\033[0m"
    echo -e "\033[1;37m[d] Password for L2TP: $L2TP_PASSWORD\033[0m"
    echo -e "\033[1;37m[d] Use debug functions: $DEBUG\033[0m"

    echo -e "\033[1;37m[i] Creating special file /etc/ppp/options.l2tpd.client...\033[0m"

    if [ $DEBUG = 1 ]; then
        cat << EOF > /etc/ppp/options.l2tpd.client
# /etc/ppp/options.l2tpd.client

ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
idle 1800

persist
lcp-echo-interval 10
lcp-echo-failure 5

mtu 1300
mru 1300
defaultroute
usepeerdns
debug
logfile /tmp/ppp.log
name "$L2TP_USERNAME"
password "$L2TP_PASSWORD"
EOF
    else
        cat << EOF > /etc/ppp/options.l2tpd.client
# /etc/ppp/options.l2tpd.client

ipcp-accept-local
ipcp-accept-remote
refuse-eap
require-mschap-v2
noccp
noauth
idle 1800

persist
lcp-echo-interval 10
lcp-echo-failure 5

mtu 1300
mru 1300
defaultroute
usepeerdns
name "$L2TP_USERNAME"
password "$L2TP_PASSWORD"
EOF
    fi

    echo -e "\033[1;32m✅ Special file /etc/ppp/options.l2tpd.client created successfully.\033[0m"

    echo -e "\033[1;37m[i] Configuring special file /etc/ipsec.conf...\033[0m"

    read -p "Enter the PSK for IPSec: " PSK
    echo -e "\033[1;37m[d] PSK for IPSec: $PSK\033[0m"

    read -p "What IKE/ESP encryption algorithm do you want to use? (ahsha1, aes128-sha1, aes256-sha1, aes128-sha256, aes256-sha256 or none, unknown): " ENCRYPTION_ALGORITHM
    echo -e "\033[1;37m[d] IKE/ESP encryption algorithm: $ENCRYPTION_ALGORITHM\033[0m"

    read -p "Name of the IPSec transport tunnel: " TUNNEL_NAME
    echo -e "\033[1;37m[d] Name of the IPSec transport tunnel: $TUNNEL_NAME\033[0m"

    echo -e "\033[1;37m[i] Creating special file /etc/ipsec.conf...\033[0m"

cat << EOF > /etc/ipsec.conf
# /etc/ipsec.conf

config setup
    uniqueids=no
    charondebug="ike 2, knl 2, cfg 2"

conn %default
    ikelifetime=60m
    keylife=20m
    rekeymargin=3m
    keyingtries=1
    keyexchange=ikev1
    authby=secret

conn $TUNNEL_NAME
    auto=start
    type=transport
    left=%defaultroute
    leftprotoport=17/$L2TP_PORT
    rightprotoport=17/$L2TP_PORT
    right=$SERVER_IP
EOF

    if [ $ENCRYPTION_ALGORITHM == "none" || $ENCRYPTION_ALGORITHM == "unknown" ]; then
        cat << EOF >> /etc/ipsec.conf
    ike = aes128-sha1-modp1024, aes256-sha1-modp1024, aes128-sha256-modp1024, aes256-sha384-modp1024, aes128-sha1-modp2048, aes256-sha1-modp2048, aes128-sha256-modp2048, aes256-sha384-modp2048
    esp = aes128-sha1, aes256-sha1, aes128-sha256, aes256-sha384
    esp = aes128-sha1-modp1024, aes256-sha1-modp1024, aes128-sha256-modp1024, aes256-sha384-modp1024, aes128-sha1-modp2048, aes256-sha1-modp2048, aes128-sha256-modp2048, aes256-sha384-modp2048
EOF
    else
        cat << EOF >> /etc/ipsec.conf
    ike = $ENCRYPTION_ALGORITHM-modp1024, $ENCRYPTION_ALGORITHM-modp2048
    esp = $ENCRYPTION_ALGORITHM
EOF
    fi

    echo -e "\033[1;32m✅ Special file /etc/ipsec.conf created successfully.\033[0m"

    echo -e "\033[1;37m[i] Creating special file /etc/ipsec.secrets...\033[0m"

    cat << EOF > /etc/ipsec.secrets
# /etc/ipsec.secrets

%any $SERVER_IP : PSK "$PSK"
EOF

    echo -e "\033[1;32m✅ Special file /etc/ipsec.secrets created successfully.\033[0m"

    exit 0
}

case "$1" in
    --start)
        echo -e "\033[1;37m[i] Starting L2TP/IPSec configurator...\033[0m"
        start_only_configurator
        ;;
    --reconfigure)
        echo -e "\033[1;37m[i] Reconfiguring L2TP/IPSec...\033[0m"
        ;;
    --check)
        echo -e "\033[1;37m[i] Checking L2TP/IPSec configuration...\033[0m"
        ;;
    --help)
        echo -e "\033[1;37m[i] Using l2tp-configurator (run as: $0):\033[0m"
        echo -e "\033[1;37m[i]   --start - start L2TP/IPSec configurator\033[0m"
        echo -e "\033[1;37m[i]   --reconfigure - reconfigure L2TP/IPSec\033[0m"
        echo -e "\033[1;37m[i]   --check - check L2TP/IPSec configuration\033[0m"
        echo -e "\033[1;37m[i]   --help - show help\033[0m"
        ;;
    *)
        echo -e "\033[1;31m[E] Unknown argument: $1. Use $0 --help for help\033[0m"
        exit 1
        ;;
esac
exit 0