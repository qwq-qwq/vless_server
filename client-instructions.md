# Инструкция по подключению к VLESS VPN (WebSocket + TLS)

## Общая информация

- **Протокол**: VLESS
- **Порт**: 443
- **Шифрование**: none
- **Транспорт**: WebSocket (ws)
- **WebSocket путь**: /vlessws
- **Безопасность**: tls
- **Домен**: vless-server.perek.rest

## Настройка на различных устройствах

### Android (V2rayNG)

1. Скачайте приложение [V2rayNG из Google Play](https://play.google.com/store/apps/details?id=com.v2ray.ang)
2. Откройте приложение и нажмите на значок "+" в правом верхнем углу
3. Выберите "Import config from clipboard" и вставьте ссылку ниже:
   ```
   vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=ws&path=/vlessws&host=vless-server.perek.rest&encryption=none#YOUR_EMAIL
   ```
   Замените YOUR_UUID на ваш UUID и YOUR_EMAIL на вашу электронную почту
4. Нажмите на созданный профиль, чтобы подключиться

### iOS (Shadowrocket)

1. Скачайте приложение [Shadowrocket из App Store](https://apps.apple.com/us/app/shadowrocket/id932747118)
2. Откройте приложение и нажмите на значок "+"
3. Скопируйте ссылку:
   ```
   vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=ws&path=/vlessws&host=vless-server.perek.rest&encryption=none#YOUR_EMAIL
   ```
   Замените YOUR_UUID на ваш UUID и YOUR_EMAIL на вашу электронную почту
4. Нажмите "Start" для подключения

### Windows/macOS/Linux (Qv2ray, v2rayN, Nekoray)

1. Скачайте и установите один из клиентов:
   - [v2rayN](https://github.com/2dust/v2rayN/releases) (Windows, рекомендуется)
   - [Nekoray](https://github.com/MatsuriDayo/nekoray/releases) (Windows/Linux/macOS)
   - [Qv2ray](https://github.com/Qv2ray/Qv2ray/releases) (кросс-платформенный)

2. Добавьте новое подключение:
   - **Вариант 1**: Импортируйте ссылку:
     ```
     vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=ws&path=/vlessws&host=vless-server.perek.rest&encryption=none#YOUR_EMAIL
     ```

   - **Вариант 2**: Настройте вручную со следующими параметрами:
     - Protocol: VLESS
     - Address: vless-server.perek.rest
     - Port: 443
     - UUID: YOUR_UUID
     - Flow: (оставьте пустым)
     - Encryption: none
     - Network: WebSocket (ws)
     - Path: /vlessws
     - Host: vless-server.perek.rest
     - TLS: включено
     - SNI: vless-server.perek.rest

## Проверка подключения

После подключения вы можете проверить работу VPN, открыв сайт [ifconfig.me](https://ifconfig.me) или [ipinfo.io](https://ipinfo.io) - ваш IP-адрес должен соответствовать IP-адресу VPN-сервера.

## Решение проблем

### 1. Подключение не работает / заблокировано

**Метод 1: Использование Cloudflare CDN** (самый эффективный)

Если прямое подключение блокируется, настройте Cloudflare CDN:
1. Убедитесь, что DNS запись проксируется через Cloudflare (оранжевое облако)
2. В Cloudflare включите WebSockets (Network → WebSockets)
3. Используйте обычный connection string (трафик автоматически пойдет через Cloudflare)

Подробнее: см. `README-CDN.md`

**Метод 2: Изменить WebSocket путь**

Если путь `/vlessws` блокируется, попросите администратора изменить его на:
- `/api/v1/stream`
- `/socket`
- `/ws`
- Любой другой нейтральный путь

И обновите connection string:
```
vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=ws&path=/api/v1/stream&host=vless-server.perek.rest&encryption=none#YOUR_EMAIL
```

**Метод 3: Использовать gRPC вместо WebSocket**

gRPC сложнее обнаружить. Попросите администратора переключить на gRPC конфигурацию.

Connection string для gRPC:
```
vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=grpc&serviceName=GrpcService&mode=gun&encryption=none#YOUR_EMAIL
```

**Метод 4: Включить фрагментацию на клиенте**

В клиентах v2rayN, Nekoray:
1. Откройте настройки подключения
2. Найдите "Fragment" или "Mux"
3. Включите фрагментацию пакетов
4. Установите размер фрагмента: 100-200 байт

**Метод 5: Альтернативные порты**

Если порт 443 блокируется, через Cloudflare можно использовать:
- 2053
- 2083
- 2087
- 2096
- 8443

Просто измените порт в connection string.

### 2. Медленное соединение

- Если используете Cloudflare - это нормально, CDN может немного замедлить
- Попробуйте изменить настройки MTU в клиенте (если доступно)
- Возможно, сервер перегружен

### 3. Периодические разрывы

- Включите "Keep Alive" в настройках клиента
- Увеличьте "Timeout" до 300 секунд
- Попробуйте переключиться на gRPC (более стабилен)

В случае проблем с подключением обратитесь к администратору.

---

Примечание: Эта инструкция предназначена только для законного использования VPN. Пожалуйста, соблюдайте законодательство вашей страны.