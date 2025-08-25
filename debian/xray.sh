#!/bin/sh
echo "Starting setup Linux please wait"
pkill xray
pkill tun2socks
sleep 1

# Заполните данные переменные из
SERVER_ADDRESS="194.246.83.17"
SERVER_PORT=443
USER_ID="be2e1133-f5be-4c67-a304-1dcf9e21bfcc"
ENCRYPTION="none"
FINGERPRINT_FP="chrome"
SERVER_NAME_SNI="yahoo.com"
PUBLIC_KEY_PBK="3O2pSxyRY_GvRRYNtyPEh96W8-Gy5e_vkNoCODlnJSk"
SHORT_ID_SID="156f80841fb733"
GATEWAY=***
ADAPTER_NAME=***


# Получение IP-адреса
SERVER_IP_ADDRESS=$(getent ahosts $SERVER_ADDRESS | head -n 1 | awk '{print $1}')

if [ -z "$SERVER_IP_ADDRESS" ]; then
  echo "Failed to obtain an IP address for FQDN $SERVER_ADDRESS"
  exit 1
fi

# Сетевые настройки
ip tuntap del mode tun dev tun0
ip tuntap add mode tun dev tun0
ip addr add 172.31.200.10/30 dev tun0
ip link set dev tun0 up
ip route del default via $GATEWAY
ip route add default via 172.31.200.10
ip route add $SERVER_IP_ADDRESS/32 via $GATEWAY
ip route add 1.0.0.1/32 via $GATEWAY
ip route add 8.8.4.4/32 via $GATEWAY
ip route add 192.168.0.0/16 via $GATEWAY
ip route add 10.0.0.0/8 via $GATEWAY
ip route add 172.16.0.0/12 via $GATEWAY


# Обновление resolv.conf
rm -f /etc/resolv.conf
tee -a /etc/resolv.conf <<< "nameserver $GATEWAY"
tee -a /etc/resolv.conf <<< "nameserver 1.0.0.1"
tee -a /etc/resolv.conf <<< "nameserver 8.8.4.4"

# Генерация конфигурации для Xray
cat <<EOF > /opt/xray/config/config.json
{
  "log": {
    "loglevel": "silent"
  },
  "inbounds": [
    {
      "port": 10800,
      "listen": "0.0.0.0",
      "protocol": "socks",
      "settings": {
        "auth": "noauth",
        "udp": true
      },
      "sniffing": {
        "enabled": true,
        "destOverride": ["http", "tls", "quic"],
		"routeOnly": true
      }
    }
  ],
  "outbounds": [
    {
      "protocol": "vless",
      "settings": {
        "vnext": [
          {
            "address": "$SERVER_ADDRESS",
            "port": $SERVER_PORT,
            "users": [
              {
                "id": "$USER_ID",
                "encryption": "$ENCRYPTION",
                "alterId": 0
              }
            ]
          }
        ]
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "fingerprint": "$FINGERPRINT_FP",
          "serverName": "$SERVER_NAME_SNI",
          "publicKey": "$PUBLIC_KEY_PBK",
          "spiderX": "",
          "shortId": "$SHORT_ID_SID"
        }
      },
	  "tag": "proxy"
    }
  ]
}
EOF
echo "Start Xray core"
/opt/xray/xray run -config /opt/xray/config/config.json &
echo "Start tun2socks"
/opt/tun2socks/tun2socks -loglevel silent -tcp-sndbuf 3m -tcp-rcvbuf 3m -device tun0 -proxy socks5://127.0.0.1:10800 -interface $ADAPTER_NAME &
echo "Linux customization is complete"
