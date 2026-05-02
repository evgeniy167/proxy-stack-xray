#!/usr/bin/env bash
set -e

mkdir -p configs/xray configs/hysteria configs/mtg output/qr

SERVER_IP=$(curl -4 -s ifconfig.me)
UUID=$(cat /proc/sys/kernel/random/uuid)

XRAY_KEYS=$(docker run --rm ghcr.io/xtls/xray-core:latest x25519)
PRIVATE_KEY=$(echo "$XRAY_KEYS" | awk '/PrivateKey:/ {print $2}')
PUBLIC_KEY=$(echo "$XRAY_KEYS" | awk -F': ' '/PublicKey/ {print $2}')

SHORT_ID=$(openssl rand -hex 8)
HY_PASSWORD=$(openssl rand -hex 8)
SOCKS_USER="user$(shuf -i 1000-9999 -n 1)"
SOCKS_PASS=$(openssl rand -hex 8)

MTG_SECRET_8888=$(docker run --rm nineseconds/mtg:latest generate-secret www.cloudflare.com)
MTG_SECRET_2095=$(docker run --rm nineseconds/mtg:latest generate-secret www.microsoft.com)

openssl req -x509 -newkey rsa:2048 -nodes \
  -keyout configs/hysteria/server.key \
  -out configs/hysteria/server.crt \
  -days 3650 \
  -subj "/CN=news.ycombinator.com" >/dev/null 2>&1

cat > configs/xray/config.json <<EOL
{
  "log": {
    "loglevel": "warning"
  },
  "dns": {
    "servers": [
      "1.1.1.1",
      "1.0.0.1",
      "8.8.8.8"
    ]
  },
  "inbounds": [
    {
      "tag": "vless-reality-in",
      "listen": "0.0.0.0",
      "port": 443,
      "protocol": "vless",
      "settings": {
        "clients": [
          {
            "id": "$UUID",
            "flow": "xtls-rprx-vision"
          }
        ],
        "decryption": "none"
      },
      "streamSettings": {
        "network": "tcp",
        "security": "reality",
        "realitySettings": {
          "show": false,
          "dest": "www.cloudflare.com:443",
          "xver": 0,
          "serverNames": [
            "www.cloudflare.com"
          ],
          "privateKey": "$PRIVATE_KEY",
          "shortIds": [
            "$SHORT_ID"
          ]
        }
      }
    },
    {
      "tag": "socks5-in",
      "listen": "0.0.0.0",
      "port": 1080,
      "protocol": "socks",
      "settings": {
        "auth": "password",
        "accounts": [
          {
            "user": "$SOCKS_USER",
            "pass": "$SOCKS_PASS"
          }
        ],
        "udp": true,
        "ip": "0.0.0.0"
      },
      "sniffing": {
        "enabled": true,
        "destOverride": [
          "http",
          "tls",
          "quic"
        ]
      }
    }
  ],
  "outbounds": [
    {
      "tag": "direct",
      "protocol": "freedom"
    },
    {
      "tag": "block",
      "protocol": "blackhole"
    }
  ],
  "routing": {
    "domainStrategy": "IPIfNonMatch",
    "rules": [
      {
        "type": "field",
        "protocol": [
          "bittorrent"
        ],
        "outboundTag": "block"
      }
    ]
  }
}
EOL

cat > configs/hysteria/config.yaml <<EOL
listen: :2053

tls:
  cert: /etc/hysteria/server.crt
  key: /etc/hysteria/server.key

auth:
  type: password
  password: $HY_PASSWORD

masquerade:
  type: proxy
  proxy:
    url: https://news.ycombinator.com
EOL

cat > configs/mtg/mtg-8888.toml <<EOL
secret = "$MTG_SECRET_8888"
bind-to = "0.0.0.0:8888"
EOL

cat > configs/mtg/mtg-2095.toml <<EOL
secret = "$MTG_SECRET_2095"
bind-to = "0.0.0.0:2095"
EOL

cat > .env <<EOL
SOCKS_USER=$SOCKS_USER
SOCKS_PASS=$SOCKS_PASS
MTG_SECRET_8888=$MTG_SECRET_8888
MTG_SECRET_2095=$MTG_SECRET_2095
EOL
chmod 600 .env

VLESS_LINK="vless://$UUID@$SERVER_IP:443?security=reality&sni=www.cloudflare.com&fp=chrome&pbk=$PUBLIC_KEY&sid=$SHORT_ID&type=tcp&flow=xtls-rprx-vision#VLESS"
HY_LINK="hysteria2://$HY_PASSWORD@$SERVER_IP:2053/?insecure=1&sni=news.ycombinator.com#HY2"
MTG_LINK_8888="tg://proxy?server=$SERVER_IP&port=8888&secret=$MTG_SECRET_8888"
MTG_LINK_2095="tg://proxy?server=$SERVER_IP&port=2095&secret=$MTG_SECRET_2095"

cat > output/links.txt <<EOL
VLESS:
$VLESS_LINK

HYSTERIA2:
$HY_LINK

MTG 8888:
$MTG_LINK_8888

MTG 2095:
$MTG_LINK_2095

SOCKS5 Xray:
server: $SERVER_IP
port: 1080
user: $SOCKS_USER
pass: $SOCKS_PASS
EOL

qrencode -o output/qr/vless.png "$VLESS_LINK"
qrencode -o output/qr/hysteria.png "$HY_LINK"
qrencode -o output/qr/mtg-8888.png "$MTG_LINK_8888"
qrencode -o output/qr/mtg-2095.png "$MTG_LINK_2095"

echo "[OK] Generated:"
cat output/links.txt
