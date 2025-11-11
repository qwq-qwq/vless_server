# Инструкция по подключению к VLESS VPN (с TLS)

## Общая информация

- **Протокол**: VLESS
- **Порт**: 443
- **Шифрование**: none
- **Сеть**: tcp
- **Безопасность**: tls
- **Домен**: vless-server.perek.rest

## Настройка на различных устройствах

### Android (V2rayNG)

1. Скачайте приложение [V2rayNG из Google Play](https://play.google.com/store/apps/details?id=com.v2ray.ang)
2. Откройте приложение и нажмите на значок "+" в правом верхнем углу
3. Выберите "Import config from clipboard" и вставьте ссылку ниже:
   ```
   vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=tcp&encryption=none#YOUR_EMAIL
   ```
   Замените YOUR_UUID на ваш UUID и YOUR_EMAIL на вашу электронную почту
4. Нажмите на созданный профиль, чтобы подключиться

### iOS (Shadowrocket)

1. Скачайте приложение [Shadowrocket из App Store](https://apps.apple.com/us/app/shadowrocket/id932747118)
2. Откройте приложение и нажмите на значок "+" 
3. Скопируйте ссылку:
   ```
   vless://YOUR_UUID@vless-server.perek.rest:443?security=tls&type=tcp&encryption=none#YOUR_EMAIL
   ```
   Замените YOUR_UUID на ваш UUID и YOUR_EMAIL на вашу электронную почту
4. Нажмите "Start" для подключения

### Windows/macOS/Linux (Qv2ray)

1. Скачайте и установите [Qv2ray](https://github.com/Qv2ray/Qv2ray/releases)
2. Скачайте и установите [V2ray Core](https://github.com/v2fly/v2ray-core/releases)
3. Настройте путь к V2ray Core в настройках Qv2ray
4. Добавьте новое подключение и выберите протокол VLESS со следующими параметрами:
   - Address: vless-server.perek.rest
   - Port: 443
   - UUID: YOUR_UUID
   - Flow: (оставьте пустым)
   - Encryption: none
   - Network: tcp
   - Security: tls
   - SNI: vless-server.perek.rest

## Проверка подключения

После подключения вы можете проверить работу VPN, открыв сайт [ifconfig.me](https://ifconfig.me) или [ipinfo.io](https://ipinfo.io) - ваш IP-адрес должен соответствовать IP-адресу VPN-сервера.

## Решение проблем

1. **Не удается подключиться:**
   - Проверьте правильность UUID
   - Убедитесь, что Traefik правильно настроен и обслуживает домен vless-server.perek.rest
   - Проверьте, что сертификат Let's Encrypt был успешно получен

2. **Медленное соединение:**
   - Возможно, сервер перегружен
   - Попробуйте изменить настройки MTU в клиенте (если доступно)

В случае проблем с подключением обратитесь к администратору.

---

Примечание: Эта инструкция предназначена только для законного использования VPN. Пожалуйста, соблюдайте законодательство вашей страны.