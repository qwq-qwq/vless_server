# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Обзор проекта

Это VLESS VPN сервер, работающий в Docker контейнере с использованием Xray. Сервер интегрируется с внешним Traefik прокси для SSL/TLS терминации и маршрутизации. Проект использует Jenkins для автоматизированного деплоя.

## Архитектура

### Основные компоненты

1. **Xray (VLESS)** - запускается в Docker контейнере `teddysun/xray`, слушает порт 8443
2. **Traefik** - внешний обратный прокси, управляет SSL/TLS и маршрутизацией к контейнеру VLESS
3. **Docker Network** - `traefik_web-network` (external) связывает VLESS и Traefik

### Поток трафика

```
Клиент → [HTTPS:443 WebSocket] → Traefik → [HTTP:8443 /vlessws] → VLESS контейнер → Интернет
```

Traefik терминирует TLS соединения и проксирует HTTP/WebSocket трафик на порт 8443 VLESS контейнера. VLESS использует WebSocket транспорт на пути `/vlessws` для маскировки под обычный HTTPS трафик, что затрудняет обнаружение и блокировку.

### Конфигурационные файлы

- `config/config.json` - основная конфигурация Xray/VLESS с массивом клиентов (UUID, email)
- `docker-compose.yml` - определяет контейнер VLESS с Traefik labels для маршрутизации
- `Jenkinsfile` - пайплайн для автоматического деплоя на сервер

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

### Docker Network

```bash
# Проверить существование сети traefik_web-network
docker network ls | grep traefik_web-network

# Создать сеть (если отсутствует)
docker network create traefik_web-network
```

## Особенности конфигурации

### VLESS настройки (config/config.json)

- Протокол: VLESS
- Порт: 8443 (внутренний)
- Decryption: none
- Network: WebSocket (`ws`)
- WebSocket Path: `/vlessws`
- Fallbacks: перенаправление на порт 80 для неправильных запросов
- Клиенты хранятся в массиве `inbounds[0].settings.clients[]`
- Routing: блокировка приватных IP адресов

### Traefik Labels (docker-compose.yml)

- `traefik.http.routers.vless-https.rule` - маршрутизация по Host заголовку
- `traefik.http.routers.vless-https.entrypoints=websecure` - использует стандартный HTTPS entrypoint (443)
- `traefik.http.routers.vless-https.tls.certresolver=myresolver` - автоматические Let's Encrypt сертификаты
- `traefik.http.services.vless-service.loadbalancer.server.port=8443` - бэкенд порт
- HTTP to HTTPS редирект для маскировки под обычный веб-сервис

### Jenkins Pipeline

Пайплайн выполняет:
1. Checkout кода
2. Замену `YOUR_UUID_HERE` в config.json на UUID из Jenkins credentials
3. Создание директорий в `/opt/projects/vless-server`
4. Копирование конфигурации на сервер
5. Проверку/создание Docker сети
6. Запуск контейнера через docker-compose

**Credentials**: требуется Jenkins credential с ID `vless-uuid`.

## Connection String формат

```
vless://{UUID}@{DOMAIN}:443?security=tls&type=ws&path=/vlessws&host={DOMAIN}&encryption=none#{EMAIL}
```

Пример:
```
vless://550e8400-e29b-41d4-a716-446655440000@vless-server.perek.rest:443?security=tls&type=ws&path=/vlessws&host=vless-server.perek.rest&encryption=none#sergey@perek.rest
```

**Важные параметры:**
- `type=ws` - использование WebSocket транспорта
- `path=/vlessws` - WebSocket путь (должен совпадать с wsSettings.path в config.json)
- `host={DOMAIN}` - заголовок Host для WebSocket handshake
- `security=tls` - TLS шифрование обрабатывается Traefik

## Зависимости и требования

- Docker и Docker Compose
- Внешний Traefik с entrypoints `web` (80) и `websecure` (443), certresolver `myresolver`
- Docker сеть `traefik_web-network` (должна быть создана заранее)
- Домен `vless-server.perek.rest` указывающий на сервер
- Открытые порты 80 и 443 на хосте для Traefik
- `jq` для работы `manage-users.sh`