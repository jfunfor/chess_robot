## Dockerfile для фронтенда
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