from django.http import JsonResponse
import os

def status(request):
    return JsonResponse({
        'status': 'ok',
        'message': 'Django API is running',
        'version': os.environ.get('APP_VERSION', '1.0.0'),
        'environment': os.environ.get('DEBUG', 'False')
    })
