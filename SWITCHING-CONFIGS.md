# Быстрое переключение между конфигурациями

Этот репозиторий содержит несколько конфигураций для разных методов обхода блокировок.

## 📦 Доступные конфигурации

| Конфигурация | Файл | Назначение | Эффективность обхода |
|--------------|------|------------|---------------------|
| **Reality (текущая)** | `config/config.json` | Прямое подключение без CDN | ⭐⭐ (блокируется в некоторых регионах) |
| **WebSocket + CDN** | `config/config-websocket-cdn.json` | Cloudflare CDN маскировка | ⭐⭐⭐⭐⭐ |
| **gRPC + CDN** | `config/config-grpc-cdn.json` | Лучшая обфускация через gRPC | ⭐⭐⭐⭐⭐ |

## 🔄 Как переключиться

### Метод 1: WebSocket + Cloudflare (Рекомендуется для Луганской области)

```bash
cd /opt/projects/vless-server

# Резервная копия текущей конфигурации
cp config/config.json config/config-reality-backup.json
cp docker-compose.yml docker-compose-reality-backup.yml

# Переключение на WebSocket
cp config/config-websocket-cdn.json config/config.json
cp docker-compose-cdn.yml docker-compose.yml

# Перезапуск
docker-compose down && docker-compose up -d

# Проверка логов
docker-compose logs -f
```

**Важно:** После переключения:
1. Настройте Cloudflare CDN (см. `BYPASS-GUIDE.md` → Метод 1)
2. Получите новые connection strings: `./manage-users.sh list`

### Метод 2: gRPC + Cloudflare (Максимальная обфускация)

```bash
cd /opt/projects/vless-server

# Резервная копия
cp config/config.json config/config-backup.json
cp docker-compose.yml docker-compose-backup.yml

# Переключение на gRPC
cp config/config-grpc-cdn.json config/config.json
cp docker-compose-cdn.yml docker-compose.yml

# Перезапуск
docker-compose down && docker-compose up -d
```

### Возврат к Reality

```bash
cd /opt/projects/vless-server

# Восстановление из резервной копии
cp config/config-reality-backup.json config/config.json
cp docker-compose-reality-backup.yml docker-compose.yml

# Перезапуск
docker-compose down && docker-compose up -d
```

## 🛠️ После переключения конфигурации

1. **Получите новые connection strings:**
   ```bash
   ./manage-users.sh list
   ```

2. **Обновите конфигурацию клиентов:**
   - Замените старые connection strings на новые
   - Для WebSocket/gRPC используйте порты Cloudflare (443, 2053, 2083, 2087, 2096, 8443)

3. **Настройте Cloudflare (если используете WebSocket/gRPC):**
   - Включите проксирование (оранжевое облако) для DNS записи
   - Включите WebSockets: Network → WebSockets → On
   - SSL/TLS Mode: Full (strict)

## 📊 Сравнение производительности

| Конфигурация | Скорость | Стабильность | Обход блокировок | Сложность настройки |
|--------------|----------|--------------|------------------|---------------------|
| Reality | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐ | ⭐ |
| WebSocket + CDN | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐ |
| gRPC + CDN | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |

## ⚠️ Важные замечания

1. **UUID остаются теми же** - при переключении конфигураций UUID клиентов не меняются, меняется только транспорт

2. **Cloudflare требуется** для WebSocket и gRPC конфигураций:
   - Без Cloudflare эти конфигурации не будут работать с прямым подключением
   - Reality работает БЕЗ Cloudflare

3. **Порты:**
   - Reality: использует порт 443 напрямую
   - WebSocket/gRPC: внутренний порт 8443, внешний через Traefik (443) или Cloudflare (443, 2053, 2083, etc.)

4. **Traefik labels:**
   - `docker-compose.yml` (Reality) использует TCP router с TLS passthrough
   - `docker-compose-cdn.yml` (WebSocket/gRPC) использует HTTP router без passthrough

## 🔍 Проверка текущей конфигурации

```bash
# Проверить тип транспорта
jq -r '.inbounds[0].streamSettings.network' config/config.json

# Проверить security
jq -r '.inbounds[0].streamSettings.security' config/config.json

# Вывод:
# tcp + reality = Reality
# ws + none = WebSocket (CDN)
# grpc + none = gRPC (CDN)
```

## 📞 Помощь

Подробные инструкции:
- **Обход блокировок:** `BYPASS-GUIDE.md`
- **Настройка клиентов:** `client-instructions.md`
- **Общая информация:** `README.md`
- **Разработка:** `CLAUDE.md`
