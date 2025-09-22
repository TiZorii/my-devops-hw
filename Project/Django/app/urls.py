from django.contrib import admin
from django.urls import path, include
from django.http import JsonResponse
from django.views.generic import TemplateView
import os

def health_check(request):
    """Simple health check endpoint"""
    return JsonResponse({
        'status': 'healthy',
        'version': os.environ.get('APP_VERSION', '1.0.0'),
        'environment': os.environ.get('DEBUG', 'False'),
        'database': 'connected'  # You can add actual DB check here
    })

def info_view(request):
    """Application info endpoint"""
    return JsonResponse({
        'app_name': 'Django DevOps Final Project',
        'version': os.environ.get('APP_VERSION', '1.0.0'),
        'build_number': os.environ.get('BUILD_NUMBER', 'unknown'),
        'git_commit': os.environ.get('GIT_COMMIT', 'unknown'),
        'environment': 'development' if os.environ.get('DEBUG', 'False') == 'True' else 'production',
        'database_host': os.environ.get('DATABASE_HOST', 'localhost'),
        'features': [
            'REST API',
            'Health Checks',
            'Auto Scaling',
            'Monitoring Ready'
        ]
    })

urlpatterns = [
    path('admin/', admin.site.urls),
    path('health/', health_check, name='health'),
    path('info/', info_view, name='info'),
    path('api/', include('api.urls')),
    path('', TemplateView.as_view(template_name='index.html'), name='home'),
]