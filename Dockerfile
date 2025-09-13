# Використовуємо Python 3.9 як базовий образ
FROM python:3.9

# Встановлюємо змінні оточення
ENV PYTHONDONTWRITEBYTECODE=1
ENV PYTHONUNBUFFERED=1

# Встановлюємо робочу директорію
WORKDIR /app

# Копіюємо файл з залежностями
COPY requirements.txt /app/

# Встановлюємо залежності
RUN pip install --no-cache-dir -r requirements.txt

# Копіюємо код проекту
COPY . /app/

# Відкриваємо порт 8000
EXPOSE 8000

# Команда для запуску Django сервера
CMD ["gunicorn", "--bind", "0.0.0.0:8000", "myproject.wsgi:application"]