#!/usr/bin/env bash
set -e

apt update
apt install -y curl git openssl qrencode ca-certificates

if ! command -v docker >/dev/null 2>&1; then
  curl -fsSL https://get.docker.com | sh
fi

systemctl enable docker
systemctl start docker

chmod +x generate.sh

rm -rf configs output .env

./generate.sh

docker compose up -d

echo
echo "===== LINKS ====="
cat output/links.txt

echo
echo "===== PORTS ====="
ss -tulpn | grep -E '443|2053|1080|8888|2095' || true
