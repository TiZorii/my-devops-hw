from django.shortcuts import render
from django.http import HttpResponse

def home(request):
    return HttpResponse("""
    <html>
    <head>
        <title>Docker Django App</title>
        <style>
            body { font-family: Arial, sans-serif; text-align: center; margin-top: 100px; }
            h1 { color: #4CAF50; }
            p { font-size: 18px; }
        </style>
    </head>
    <body>
        <h1>🐳 Django + Docker + PostgreSQL + Nginx</h1>
        <p>Вітаємо! Ваш Docker проект працює успішно!</p>
        <p>✅ Django запущений</p>
        <p>✅ PostgreSQL підключений</p>
        <p>✅ Nginx працює</p>
    </body>
    </html>
    """)