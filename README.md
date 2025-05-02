# VLESS VPN Server с внешним Traefik

Этот репозиторий содержит конфигурацию Docker и Jenkins Pipeline для разворачивания VLESS VPN сервера, используя внешний Traefik в качестве обратного прокси.

## Структура проекта

```
vless-server/
├── config/
│   └── config.json         # Основная конфигурация VLESS
├── docker-compose.yml      # Docker Compose конфигурация для работы с внешним Traefik
├── Jenkinsfile             # Jenkins Pipeline для автоматического деплоя
├── manage-users.sh         # Скрипт для управления пользователями
└── client-instructions.md  # Инструкции для клиентов по подключению
```

## Предварительные требования

- Docker и Docker Compose
- Jenkins (для автоматического деплоя)
- Работающий внешний Traefik, настроенный в проекте jenkins-installer
- Сеть Docker с именем traefik_web-network
- Домен vless-server.perek.rest (или другой, указанный при настройке)
- Открытые порты 80 и 443 на вашем сервере

## Быстрый старт

### Автоматическая установка через Jenkins

1. Создайте новый Pipeline проект в Jenkins
2. Настройте получение кода из Git-репозитория
3. Добавьте параметры:
   - `DOMAIN` - ваш домен (по умолчанию vless-server.perek.rest)
   - `UUID` - (опционально) UUID для VLESS клиента

4. Запустите пайплайн

Процесс установки включает:
- Создание необходимых директорий
- Генерацию UUID (если не указан)
- Настройку домена
- Проверку и создание сети Docker traefik_web-network
- Запуск сервера

### Управление пользователями

#### Добавление нового пользователя

```bash
./manage-users.sh add client@example.com
```

#### Удаление пользователя

```bash
./manage-users.sh remove client@example.com
```

#### Просмотр списка пользователей

```bash
./manage-users.sh list
```

После добавления или удаления пользователей перезапустите сервер:
```bash
docker-compose restart
```

## Интеграция с внешним Traefik

Этот проект предполагает, что у вас уже есть работающий Traefik, настроенный в проекте jenkins-installer. Основные моменты интеграции:

1. **Docker сеть** - VLESS подключается к сети `traefik_web-network`, где работает Traefik
2. **Labels** - Контейнер VLESS имеет метки (labels), которые Traefik использует для маршрутизации
3. **SSL** - Traefik автоматически обрабатывает SSL-сертификаты и TLS-соединения

## Решение проблем

1. **Сервер не запускается:**
   - Проверьте логи: `docker-compose logs`
   - Убедитесь, что сеть traefik_web-network существует: `docker network ls | grep traefik_web-network`
   - Проверьте, что Traefik правильно настроен и работает: `docker ps | grep traefik`

2. **Проблемы с подключением к VLESS:**
   - Проверьте статус сервера: `docker-compose ps`
   - Убедитесь, что Traefik правильно маршрутизирует трафик на VLESS
   - Проверьте правильность UUID и других параметров

3. **Traefik не видит VLESS:**
   - Убедитесь, что оба контейнера находятся в одной сети (traefik_web-network)
   - Проверьте метки (labels) в docker-compose.yml

## Мониторинг

Для простого мониторинга сервера можно использовать скрипт:

```bash
./monitor.sh
```

Он проверит:
- Статус контейнера VLESS
- Наличие сети traefik_web-network
- Статус Traefik
- Активные соединения
- Использование ресурсов