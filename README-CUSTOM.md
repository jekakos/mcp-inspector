# MCP Inspector - Custom Docker Setup

Этот кастомный Docker setup позволяет запустить MCP Inspector (сервер + клиент) на одном инстансе для развертывания через Coolify.

## Файлы

- `Dockerfile.custom` - Кастомный Dockerfile для сборки образа
- `start-inspector.sh` - Скрипт запуска сервера и клиента
- `docker-compose.custom.yml` - Docker Compose конфигурация
- `README-CUSTOM.md` - Эта инструкция

## Порты

- **3000** - Клиент (веб-интерфейс)
- **6277** - Сервер (API)

## Быстрый старт

### 1. Сборка образа

```bash
docker build -f Dockerfile.custom -t mcp-inspector-custom .
```

### 2. Запуск через Docker

```bash
docker run -d \
  --name mcp-inspector \
  -p 3000:3000 \
  -p 6277:6277 \
  mcp-inspector-custom
```

### 3. Локальное тестирование (опционально)

Для локального тестирования можно использовать Docker Compose:

```bash
# Создайте docker-compose.yml с содержимым:
version: '3.8'
services:
  mcp-inspector:
    build:
      context: .
      dockerfile: Dockerfile.custom
    ports:
      - "3000:3000"
      - "6277:6277"
    environment:
      - CLIENT_PORT=3000
      - SERVER_PORT=6277
    restart: unless-stopped

# Затем запустите:
docker-compose up -d
```

## Доступ к приложению

После запуска MCP Inspector будет доступен по адресу:
- **Клиент**: http://localhost:3000
- **Сервер API**: http://localhost:6277

## Переменные окружения

- `CLIENT_PORT` - Порт клиента (по умолчанию: 3000)
- `SERVER_PORT` - Порт сервера (по умолчанию: 6277)
- `MCP_PROXY_AUTH_TOKEN` - Токен аутентификации (генерируется автоматически)

## Аутентификация

MCP Inspector использует токен аутентификации для безопасного взаимодействия между клиентом и сервером:

- **Автоматическая генерация**: Токен генерируется автоматически при запуске
- **Передача токена**: Токен автоматически передается от сервера к клиенту через переменные окружения
- **Использование**: Клиент использует токен в заголовке `X-MCP-Proxy-Auth: Bearer <token>` для всех запросов к серверу

### Прямой доступ к серверу

Если вам нужно обратиться к серверу напрямую (например, для API вызовов), используйте токен:

```bash
curl -H "X-MCP-Proxy-Auth: Bearer <your-token>" http://localhost:6277/config
```

Токен отображается в логах при запуске контейнера.

## Развертывание в Coolify

1. Создайте новый проект в Coolify
2. Подключите этот репозиторий
3. Укажите `Dockerfile.custom` как Dockerfile
4. Настройте порты:
   - 3000 (клиент)
   - 6277 (сервер)
5. Запустите развертывание

## Логи

Для просмотра логов:

```bash
docker logs -f mcp-inspector
```

## Остановка

```bash
docker stop mcp-inspector
docker rm mcp-inspector
```

Или через Docker Compose (если использовали):

```bash
docker-compose down
```

## Health Check

Контейнер включает health check, который проверяет доступность клиента на порту 3000.

## Troubleshooting

### Проблемы с портами

Убедитесь, что порты 3000 и 6277 свободны:

```bash
netstat -tulpn | grep :3000
netstat -tulpn | grep :6277
```

### Проблемы с запуском

Проверьте логи контейнера:

```bash
docker logs mcp-inspector
```

### Перезапуск сервисов

Если нужно перезапустить только один из сервисов:

```bash
# Перезапуск сервера
docker exec mcp-inspector pkill -f "node build/index.js"

# Перезапуск клиента  
docker exec mcp-inspector pkill -f "node bin/client.js"
```
