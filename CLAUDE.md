# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Обзор проекта

Это VLESS + XTLS Reality VPN сервер, работающий в Docker контейнере с использованием Xray. Сервер работает **напрямую на порту 443 БЕЗ Traefik**, используя протокол Reality для маскировки под обычный HTTPS трафик к microsoft.com. Проект использует Jenkins для автоматизированного деплоя.

## Архитектура

### Основные компоненты

1. **Xray (VLESS + XTLS Reality)** - запускается в Docker контейнере `teddysun/xray`, слушает порт 443
2. **Протокол Reality** - маскируется под TLS соединение к microsoft.com, неотличим от обычного HTTPS
3. **Прямое подключение** - работает БЕЗ Traefik на порту 443

### Поток трафика

```
Авторизованный клиент → [Reality TLS:443] → VLESS контейнер → Интернет
Цензор/посторонний → [Reality TLS:443] → VLESS контейнер → microsoft.com (проксирование)
```

Reality использует протокол XTLS для маскировки:
- При подключении **авторизованного клиента** (с правильным Public Key) - работает как VPN
- При подключении **цензора или постороннего** - проксирует трафик на настоящий microsoft.com
- DPI видит обычный HTTPS к microsoft.com с правильным сертификатом Microsoft
- **Никаких следов VPN/прокси**

### Конфигурационные файлы

- `config/config.json` - основная конфигурация Xray VLESS + Reality (UUID, Private Key, dest: microsoft.com)
- `docker-compose.yml` - определяет контейнер VLESS с прямым пробросом порта 443 (БЕЗ Traefik)
- `Jenkinsfile` - пайплайн для автоматического деплоя (заменяет UUID и Private Key из Jenkins secrets)
- `REALITY-WITHOUT-TRAEFIK.md` - документация о текущей рабочей конфигурации

## Команды разработки

### Управление сервером

```bash
# Запуск сервера
docker-compose up -d

# Остановка сервера
docker-compose down

# Перезапуск (необходим после изменения config.json)
docker-compose restart

# Просмотр логов
docker-compose logs
docker-compose logs -f  # следить за логами в реальном времени

# Проверка статуса
docker-compose ps
```

### Управление пользователями

Используйте скрипт `manage-users.sh` для управления клиентами VLESS:

```bash
# Добавить пользователя (генерирует UUID, обновляет config.json, перезапускает контейнер)
./manage-users.sh add client@example.com

# Удалить пользователя
./manage-users.sh remove client@example.com

# Список пользователей с connection strings
./manage-users.sh list
```

**Важно**: Скрипт требует установленный `jq` для манипуляции JSON.

## Особенности конфигурации

### VLESS + Reality настройки (config/config.json)

- Протокол: VLESS
- Порт: 443 (прямой проброс)
- Flow: xtls-rprx-vision (оптимизация скорости)
- Decryption: none
- Network: TCP (не WebSocket!)
- Security: reality
- Dest: www.microsoft.com:443 (сайт-маскировка)
- ServerNames: ["www.microsoft.com", "microsoft.com"]
- PrivateKey: хранится в Jenkins secrets (vless-private-key)
- ShortIds: ["", "0123456789abcdef"]
- Клиенты хранятся в массиве `inbounds[0].settings.clients[]`
- Routing: блокировка приватных IP адресов и BitTorrent

### Jenkins Pipeline

Пайплайн выполняет:
1. Checkout кода
2. Замену `YOUR_UUID_HERE` на UUID из Jenkins credentials (`vless-uuid`)
3. Замену `YOUR_PRIVATE_KEY_HERE` на Private Key из Jenkins credentials (`vless-private-key`)
4. Создание директорий в `/opt/projects/vless-server`
5. Копирование конфигурации на сервер
6. Запуск контейнера через docker-compose

**Credentials**:
- `vless-uuid` - UUID клиента
- `vless-private-key` - Private key для Reality (сгенерирован через `xray x25519`)

## Connection String формат (Reality)

```
vless://{UUID}@{DOMAIN}:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk={PUBLIC_KEY}&sid=0123456789abcdef&type=tcp#{NAME}
```

**Рабочий пример:**
```
vless://e08d5933-f3ba-4b7c-b3d5-2661088924d5@v-server.perek.rest:443?encryption=none&flow=xtls-rprx-vision&security=reality&sni=www.microsoft.com&fp=chrome&pbk=ipuCVX0VbAiTwR7g-3If3FDdfbm1KdcJJNs09umlZi0&sid=0123456789abcdef&type=tcp#Reality-VServer
```

**Важные параметры:**
- `type=tcp` - TCP соединение (не WebSocket!)
- `security=reality` - протокол Reality
- `sni=www.microsoft.com` - SNI для маскировки
- `fp=chrome` - TLS fingerprint (имитация браузера Chrome)
- `pbk=...` - Public Key (пара к Private Key на сервере)
- `sid=0123456789abcdef` - Short ID
- `flow=xtls-rprx-vision` - оптимизация XTLS

## Зависимости и требования

- Docker и Docker Compose
- Домен `v-server.perek.rest` указывающий на сервер (IP: 104.248.100.73)
- Открытый порт 443 на хосте (БЕЗ Traefik!)
- Jenkins с credentials: `vless-uuid` и `vless-private-key`

**ВАЖНО:** Traefik должен быть остановлен, так как Reality занимает порт 443.

## Обход блокировок

### Почему Reality лучше всех для России (2025)

1. **Полная невидимость для DPI**
   - Трафик неотличим от обычного HTTPS к microsoft.com
   - При сканировании цензором - показывает настоящий сайт Microsoft
   - Нет паттернов VPN/прокси

2. **Не требует Cloudflare CDN**
   - CDN часто блокируется в России
   - Reality работает напрямую с сервером
   - Не зависит от внешних сервисов

3. **Высокая скорость**
   - XTLS Vision устраняет двойное шифрование
   - TCP вместо WebSocket = меньше оверхеда
   - BBR congestion control для оптимизации

4. **Устойчивость к активному сканированию**
   - Неавторизованные подключения идут на microsoft.com
   - Нет способа отличить от настоящего сайта
   - Public/Private key аутентификация

### Альтернативные домены для маскировки

Вместо microsoft.com можно использовать (в config.json):
- `www.apple.com` - Apple
- `www.cloudflare.com` - Cloudflare
- `www.github.com` - GitHub
- `www.amazon.com` - Amazon

Критерии выбора:
- ✅ Популярный сайт (много легитимного трафика)
- ✅ Точно не заблокирован в России
- ✅ Использует современный TLS