# Руководство по обходу жестких блокировок (Луганская область и другие регионы)

## 🚨 Проблема

Даже правильно настроенный Reality протокол может блокироваться в регионах с продвинутыми DPI системами (Deep Packet Inspection), такими как:
- Луганская и Донецкая области (ТСПУ)
- Некоторые регионы РФ
- Территории с использованием технологий Great Firewall

## 🛡️ Многоуровневая стратегия обхода

### Метод 1: Cloudflare CDN + WebSocket (⭐⭐⭐⭐⭐ Самый эффективный)

**Преимущества:**
- ✅ Скрывает реальный IP сервера за Cloudflare
- ✅ Трафик выглядит как обычный HTTPS к крупному CDN
- ✅ DPI видит только соединение к Cloudflare (которое блокировать невозможно)
- ✅ Работает через порты: 443, 2053, 2083, 2087, 2096, 8443

#### Шаг 1: Настройка Cloudflare

1. **Добавьте домен в Cloudflare** (если еще не добавлен)

2. **Создайте DNS запись:**
   ```
   Type: A
   Name: v-server (или @)
   IPv4: [IP_ВАШЕГО_СЕРВЕРА]
   Proxy status: Proxied (оранжевое облако) ✅
   TTL: Auto
   ```

3. **Настройте SSL/TLS (КРИТИЧНО!):**
   - SSL/TLS → Overview → Encryption mode: **Full (strict)** или **Full**
   - SSL/TLS → Edge Certificates:
     - Always Use HTTPS: ✅
     - Minimum TLS Version: TLS 1.2
     - Opportunistic Encryption: ✅
     - TLS 1.3: ✅
     - Automatic HTTPS Rewrites: ✅

   **Важно:** НЕ используйте "Flexible" - это не будет работать!

4. **WebSocket поддержка:**
   - ✅ WebSocket **включен по умолчанию** на всех планах Cloudflare (с 2020 года)
   - Никаких дополнительных настроек не требуется
   - Если в разделе Network → WebSockets есть переключатель - убедитесь что он ON

5. **Дополнительная обфускация (опционально):**
   - Speed → Optimization:
     - Auto Minify: включите все (JavaScript, CSS, HTML)
     - Brotli: ✅
   - Caching → Configuration:
     - Caching Level: Standard

#### Шаг 2: Переключение сервера на WebSocket

На сервере выполните:

```bash
cd /opt/projects/vless-server

# Сделайте резервную копию текущей конфигурации
cp config/config.json config/config-reality-backup.json
cp docker-compose.yml docker-compose-reality-backup.yml

# Переключитесь на WebSocket конфигурацию
cp config/config-websocket-cdn.json config/config.json
cp docker-compose-cdn.yml docker-compose.yml

# Перезапустите контейнер
docker-compose down
docker-compose up -d

# Проверьте логи
docker-compose logs -f
```

#### Шаг 3: Connection String для клиентов

```
vless://YOUR_UUID@v-server.perek.rest:443?security=tls&type=ws&path=/api/v2/metrics&host=v-server.perek.rest&encryption=none#Cloudflare-WebSocket
```

**Альтернативные порты (если 443 блокируется):**
```
vless://YOUR_UUID@v-server.perek.rest:2053?security=tls&type=ws&path=/api/v2/metrics&host=v-server.perek.rest&encryption=none#CF-Port-2053
vless://YOUR_UUID@v-server.perek.rest:2083?security=tls&type=ws&path=/api/v2/metrics&host=v-server.perek.rest&encryption=none#CF-Port-2083
vless://YOUR_UUID@v-server.perek.rest:2087?security=tls&type=ws&path=/api/v2/metrics&host=v-server.perek.rest&encryption=none#CF-Port-2087
vless://YOUR_UUID@v-server.perek.rest:2096?security=tls&type=ws&path=/api/v2/metrics&host=v-server.perek.rest&encryption=none#CF-Port-2096
vless://YOUR_UUID@v-server.perek.rest:8443?security=tls&type=ws&path=/api/v2/metrics&host=v-server.perek.rest&encryption=none#CF-Port-8443
```

---

### Метод 2: gRPC через Cloudflare (⭐⭐⭐⭐⭐ Лучшая обфускация)

**Преимущества:**
- ✅ gRPC выглядит как обычные API вызовы (Google, Яндекс используют gRPC)
- ✅ Еще сложнее детектировать чем WebSocket
- ✅ Более стабилен при плохом соединении

#### Настройка на сервере:

```bash
cd /opt/projects/vless-server

# Переключитесь на gRPC конфигурацию
cp config/config-grpc-cdn.json config/config.json
cp docker-compose-cdn.yml docker-compose.yml

# Перезапустите
docker-compose down
docker-compose up -d
```

#### Connection String:

```
vless://YOUR_UUID@v-server.perek.rest:443?security=tls&type=grpc&serviceName=GrpcDataService&mode=multi&encryption=none#Cloudflare-gRPC
```

**Альтернативные порты:**
```
vless://YOUR_UUID@v-server.perek.rest:2053?security=tls&type=grpc&serviceName=GrpcDataService&mode=multi&encryption=none#CF-gRPC-2053
```

---

### Метод 3: Клиентская фрагментация (⭐⭐⭐⭐ Дополнительная защита)

Фрагментация разбивает TLS ClientHello на мелкие пакеты, что затрудняет анализ DPI.

#### Windows: GoodbyeDPI

1. **Скачайте GoodbyeDPI:**
   - https://github.com/ValdikSS/GoodbyeDPI/releases
   - Распакуйте архив

2. **Создайте файл `run-vpn.bat`:**
   ```batch
   @echo off
   goodbyedpi.exe -5 -e1 -q --set-ttl 4 --wrong-chksum --wrong-seq --native-frag
   pause
   ```

3. **Запустите от имени администратора** перед подключением к VPN

#### Linux: zapret

1. **Установка:**
   ```bash
   git clone https://github.com/bol-van/zapret.git
   cd zapret
   ./install_easy.sh
   ```

2. **Настройка для VLESS:**
   Выберите режим: "tpws" или "nfqws"

3. **Запуск:**
   ```bash
   sudo systemctl start zapret
   sudo systemctl enable zapret
   ```

#### Android: использование встроенной фрагментации

В **v2rayNG**:
1. Настройки → Routing Settings
2. Enable Fragment: ✅
3. Fragment Size: 100-200
4. Fragment Interval: 10-50

---

### Метод 4: Изменение WebSocket пути (⭐⭐⭐ Простой обход сигнатур)

Если путь `/vlessws` или `/api/v2/metrics` детектируется, измените его на нейтральный:

**Хорошие варианты путей:**
```
/socket.io/
/ws/
/graphql
/api/v1/stream
/live
/chat
/_ws
/notifications
```

**Плохие варианты (не используйте):**
```
/vless
/vmess
/proxy
/vpn
/tunnel
```

**Как изменить:**

1. В `config/config.json` (или `config-websocket-cdn.json`):
   ```json
   "wsSettings": {
     "path": "/graphql",  // ← измените здесь
     "headers": {
       "Host": "v-server.perek.rest"
     }
   }
   ```

2. Перезапустите сервер:
   ```bash
   docker-compose restart
   ```

3. Обновите connection string:
   ```
   vless://YOUR_UUID@v-server.perek.rest:443?security=tls&type=ws&path=/graphql&host=v-server.perek.rest&encryption=none#Custom-Path
   ```

---

### Метод 5: Множественные точки входа (⭐⭐⭐⭐ Отказоустойчивость)

Настройте несколько конфигураций одновременно на разных портах.

#### Структура:

```
Port 443  → Reality (прямое подключение, для регионов без блокировок)
Port 2053 → WebSocket + Cloudflare
Port 2083 → gRPC + Cloudflare
Port 8443 → WebSocket с альтернативным путем
```

Клиенты могут переключаться между портами в зависимости от доступности.

---

## 📱 Настройка клиентов для жестких блокировок

### Android (v2rayNG)

**Базовая настройка:**
1. Импортируйте connection string (WebSocket или gRPC через Cloudflare)
2. Включите фрагментацию:
   - Три точки → Routing Settings
   - Enable Fragment: ✅
   - Fragment Size: 150
   - Fragment Interval: 20

**Дополнительные настройки:**
- Settings → Core:
  - Mux: включено, Concurrency: 8
  - Enable Sniffing: ✅
- Settings → Network:
  - Domain Strategy: AsIs
  - TCP Fast Open: ✅

### iOS (Shadowrocket / Streisand)

**Shadowrocket:**
1. Добавьте конфигурацию через connection string
2. В настройках подключения:
   - TCP Fast Open: ON
   - UDP Relay: ON
   - MUX: ON (Concurrency: 8)

**Streisand (альтернатива):**
- Лучше работает с gRPC
- Имеет встроенную обфускацию

### Windows (v2rayN / Nekoray)

**v2rayN:**
1. Импортируйте connection string
2. Настройки → Core:
   - Mux: включено (Concurrency: 8)
   - Sniffing: включено
3. **ВАЖНО:** Запустите GoodbyeDPI перед подключением!

**Nekoray (рекомендуется):**
1. Импортируйте конфигурацию
2. Edit → Extra Options:
   ```json
   {
     "mux": {
       "enabled": true,
       "concurrency": 8
     },
     "sockopt": {
       "tcpFastOpen": true,
       "tcpNoDelay": true
     }
   }
   ```

### Linux (Qv2ray / Nekoray)

**Системная фрагментация:**
```bash
# Установите zapret (см. Метод 3)
sudo systemctl start zapret
```

**Nekoray:**
- Те же настройки что и для Windows
- Работает отлично на Debian/Ubuntu

---

## 🔍 Диагностика и решение проблем

### Проблема: Подключение не устанавливается

**Проверка №1: Доступен ли сервер через Cloudflare?**
```bash
curl -I https://v-server.perek.rest
```
Должен вернуть HTTP 200 или 400 (любой ответ = сервер доступен)

**Проверка №2: Работает ли WebSocket?**
```bash
curl -i -N -H "Connection: Upgrade" -H "Upgrade: websocket" \
  -H "Host: v-server.perek.rest" \
  https://v-server.perek.rest/api/v2/metrics
```
Должен вернуть "101 Switching Protocols" или ошибку от Xray (это нормально)

**Проверка №3: Правильный ли UUID?**
В connection string должен быть UUID из `config/config.json`:
```bash
cat /opt/projects/vless-server/config/config.json | grep '"id"'
```

### Проблема: Соединение разрывается

**Решение:**
1. Попробуйте другой порт Cloudflare (2053, 2083, 2087, 2096, 8443)
2. Переключитесь с WebSocket на gRPC
3. Включите Mux в клиенте
4. Увеличьте Keep-Alive интервал

### Проблема: Медленная скорость

**Решение:**
1. Cloudflare бесплатный план ограничивает скорость - это нормально
2. Попробуйте gRPC (иногда быстрее WebSocket)
3. Проверьте что BBR включен на сервере:
   ```bash
   sysctl net.ipv4.tcp_congestion_control
   # Должно быть: net.ipv4.tcp_congestion_control = bbr
   ```

### Проблема: Периодически перестает работать

**Возможные причины:**
1. **DPI адаптируется** - попробуйте сменить WebSocket путь
2. **Cloudflare Workers limit** - используйте несколько доменов
3. **IP сервера попал в blacklist** - смените IP сервера

---

## 🎯 Рекомендуемая комбинация для Луганской области

### Настройка сервера:
1. ✅ **Cloudflare CDN с проксированием**
2. ✅ **gRPC транспорт** (более устойчив чем WebSocket)
3. ✅ **Несколько портов** (443, 2053, 2083)
4. ✅ **Нейтральный serviceName** (GrpcDataService)

### Настройка клиента:
1. ✅ **v2rayNG** (Android) или **Nekoray** (Windows/Linux)
2. ✅ **Фрагментация включена** (размер 100-200)
3. ✅ **Mux enabled** (Concurrency: 8)
4. ✅ **GoodbyeDPI/zapret** на Windows/Linux
5. ✅ **Несколько connection strings** с разными портами для переключения

### Connection String (gRPC + Cloudflare + порт 2053):
```
vless://YOUR_UUID@v-server.perek.rest:2053?security=tls&type=grpc&serviceName=GrpcDataService&mode=multi&encryption=none#LPR-Bypass
```

---

## 📊 Сравнение методов обхода

| Метод | Эффективность | Скорость | Сложность настройки | Стабильность |
|-------|---------------|----------|---------------------|--------------|
| **Reality (прямое)** | ⭐⭐ (блокируется) | ⭐⭐⭐⭐⭐ | ⭐ | ⭐⭐⭐⭐ |
| **WebSocket + CF** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐ | ⭐⭐⭐⭐⭐ |
| **gRPC + CF** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **WS + CF + Fragmentation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |
| **gRPC + CF + Fragmentation** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐ | ⭐⭐⭐⭐⭐ |

**Вывод:** Для максимальной эффективности используйте **gRPC + Cloudflare + клиентскую фрагментацию**.

---

## ⚠️ Важные замечания

1. **Cloudflare бесплатный план** имеет ограничения:
   - ~100 Гб/мес трафика (обычно достаточно)
   - Скорость может быть ниже прямого подключения
   - Возможны редкие капчи

2. **IP сервера:** После включения Cloudflare прокси **не публикуйте реальный IP сервера**! Иначе его могут заблокировать напрямую.

3. **Multiple domains:** Для отказоустойчивости настройте 2-3 поддомена:
   - v-server.perek.rest
   - vpn.perek.rest
   - proxy.perek.rest

4. **Обновления:** Следите за обновлениями Xray-core:
   ```bash
   docker pull teddysun/xray:latest
   docker-compose down
   docker-compose up -d
   ```

---

## 📞 Дополнительные ресурсы

- **Xray документация:** https://xtls.github.io/
- **GoodbyeDPI:** https://github.com/ValdikSS/GoodbyeDPI
- **zapret:** https://github.com/bol-van/zapret
- **v2rayNG:** https://github.com/2dust/v2rayNG
- **Nekoray:** https://github.com/MatsuriDayo/nekoray

---

**Создано для обхода цензуры в регионах с жесткими блокировками. Используйте ответственно и в рамках законодательства.**
