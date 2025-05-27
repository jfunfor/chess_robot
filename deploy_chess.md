# Развертывание приложения для игры в шахматы с роботом

## Создаем Dockerfile для бэкэнда
```bash
# Используем официальный образ Python в качестве базового
FROM python:3.12

# Устанавливаем рабочую директорию внутри контейнера
WORKDIR /app

# Копируем файлы зависимостей (requirements.txt)
COPY requirements.txt .

# Устанавливаем зависимости
RUN pip install --no-cache-dir -r requirements.txt

# Копируем исходный код приложения
COPY . .

# Указываем порт, который приложение слушает (важно для Kubernetes)
EXPOSE 8765

# Команда для запуска приложения
CMD ["python", "main.py"]
```
### Собираем Docker-образ бэкенда
```bash
docker build -t chess-back-actual .
```
## Создаем Dockerfile для фронтенда
```bash
# Этап сборки (builder)
FROM node:22.14.0-alpine AS builder

# Рабочая директория в контейнере
WORKDIR /app

# 1. Копируем только файлы зависимостей (чтобы кэшировать npm install)
COPY package.json package-lock.json ./

# 2. Устанавливаем зависимости
RUN npm install

# 3. Копируем ВСЕ остальные файлы проекта (кроме node_modules)
COPY . .

# 4. Собираем приложение
RUN npm run build

# Этап запуска (nginx)
FROM nginx

# Копируем собранные файлы из builder-этапа
COPY --from=builder /app/dist /usr/share/nginx/html

# (Опционально) Конфиг для SPA (чтобы Vue Router работал)
# COPY nginx.conf /etc/nginx/conf.d/default.conf

# Открываем порт 80
EXPOSE 80

# Запускаем nginx
CMD ["nginx", "-g", "daemon off;"]
```
### Собираем Docker-образ фронтенда
```bash
docker build -t chess-back-actual .
```
## Создаем файл docker-compose.yml для связи всех частей приложения

 - Указываем порты для Redis: 6379 (стандартный)
 - Указываем порты для backend: 8765:8765
 - Указываем порты для frontend: 8000:80
 - Указываем порт 10003 и ip адрес робота 10.16.0.23
```bash
  GNU nano 6.2                                                                                          docker-compose.yml                                                                                                    version: "3.8"

services:
  redis:
    image: redis:7.2
    container_name: redis
    restart: unless-stopped
    ports:
      - "6379:6379"
    volumes:
      - redis-data:/data
    command: ["redis-server", "--appendonly", "yes"]

  backend:
    image: chess-back-actual
    environment:
      REDIS_HOST: "redis"
      REDIS_PORT: 6379
      ROBOT_HOST: 10.16.0.23
      ROBOT_PORT: 10003
      DEBUG: "true"
    ports:
      - "8765:8765"  # Проброс порта бэкенда
    # environment: # Переменные окружения для бэкенда (например, настройки БД)
    #   - DATABASE_URL=...

  frontend:
    image: chess-web-actual
    ports:
      - "8000:80"  # Проброс порта веб-интерфейса (обычно 80 или 443)
    # depends_on: # Зависимости (например, frontend зависит от backend)
    #   - backend

volumes:
  redis-data:
```
*файл docker-compose.yml должен находиться рядом с основной папкой проекта chess_robot в созданной папке chess

## Запускаем контейнеры
```bash
 sudo docker-compose up -d
```
## Ссылки на репозитрии с образами 
1) Репозиторий с образом backend: https://hub.docker.com/repository/docker/nastyaaaa7373737378495/chess-back-actual/general
2) Репозиторий с образом frontend: https://hub.docker.com/repository/docker/nastyaaaa7373737378495/chess-web-actual/general

## Адрес приложения
Приложение доступно по адресу 10.160.160.148:8000 из сетей 316 и 317 кабинетов 16 корпуса.
10.160.160.148 - адрес виртуальной машины
