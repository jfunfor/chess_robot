## Dockerfile для бэкэнда
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