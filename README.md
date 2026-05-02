# Proxy Stack Xray

Чистая Docker-сборка прокси-стека для VPS без Dante.

## Что поднимается

- Xray VLESS REALITY на порту 443
- SOCKS5 через Xray на порту 1080 с логином и паролем
- Hysteria 2 на порту 2053
- MTProto proxy на портах 8888 и 2095

## Требования

- Debian 11/12 или Ubuntu 22.04/24.04
- root-доступ
- открытые порты: 443/tcp, 1080/tcp, 2053/udp, 8888/tcp, 2095/tcp

## Быстрый запуск

```bash
git clone https://github.com/evgeniy167/proxy-stack-xray.git
cd proxy-stack-xray
chmod +x install.sh
./install.sh
```

После установки ссылки и данные доступа будут выведены в терминал и сохранены в:

```bash
output/links.txt
```

## Проверка контейнеров

```bash
docker ps
```

Должны быть контейнеры:

```text
xray
hysteria
mtg1
mtg2
```

## Проверка портов

```bash
ss -tulpn | grep -E '443|2053|1080|8888|2095'
```

## Проверка SOCKS5 через Xray

```bash
source .env
curl --socks5 "$SOCKS_USER:$SOCKS_PASS@127.0.0.1:1080" https://api.ipify.org
```

Если команда вернула IP VPS, SOCKS5 работает.

## Где лежат сгенерированные файлы

```text
configs/xray/config.json
configs/hysteria/config.yaml
configs/hysteria/server.crt
configs/hysteria/server.key
configs/mtg/mtg-8888.toml
configs/mtg/mtg-2095.toml
output/links.txt
output/qr/
.env
```

## Важно

Файлы `.env`, `configs/` и `output/` не нужно коммитить в GitHub. Они создаются автоматически при запуске `install.sh`.

## Перегенерировать доступы

```bash
rm -rf configs output .env
generate.sh
docker compose restart
```

Если запускаешь из текущей папки, используй:

```bash
./generate.sh
docker compose restart
```
