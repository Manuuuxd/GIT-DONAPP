"""
Django settings for donapp project.
Sanitized Version for Documentation/Sharing.
"""

from pathlib import Path
from datetime import timedelta
import os

# Build paths inside the project like this: BASE_DIR / 'subdir'.
BASE_DIR = Path(__file__).resolve().parent.parent

# --- SECURITY WARNING ---
# In production, use environment variables (e.g., os.getenv('DJANGO_SECRET_KEY'))
SECRET_KEY = 'YOUR_SAFE_PRODUCTION_SECRET_KEY_HERE'

# SECURITY WARNING: don't run with debug turned on in production!
DEBUG = True 

# Configuración de Hosts
ALLOWED_HOSTS = ['localhost', '127.0.0.1', '10.0.2.2', '.midonapp.cl']

# Application definition
INSTALLED_APPS = [
    'django.contrib.admin',
    'django.contrib.auth',
    'django.contrib.contenttypes',
    'django.contrib.sessions',
    'django.contrib.messages',
    'django.contrib.staticfiles',
    'rest_framework',
    'rest_framework.authtoken',
    'corsheaders',
    'django_extensions',
    # Local Apps
    'trivia',
    'usuarios',
    'elegibilidad',
    'campanias',
    'appointments',
    'survey',
    'chats',
    'Whatsapp',
    'logros',
    'desafios',
    'historias',
]

MIDDLEWARE = [
    'corsheaders.middleware.CorsMiddleware',
    'django.middleware.security.SecurityMiddleware',
    'django.contrib.sessions.middleware.SessionMiddleware',
    'django.middleware.common.CommonMiddleware',
    'django.middleware.csrf.CsrfViewMiddleware',
    'django.contrib.auth.middleware.AuthenticationMiddleware',
    'django.contrib.messages.middleware.MessageMiddleware',
    'django.middleware.clickjacking.XFrameOptionsMiddleware',
]

CORS_ORIGIN_ALLOW_ALL = True # Ajustar a False en producción con CORS_ALLOWED_ORIGINS
ROOT_URLCONF = 'donapp.urls'

TEMPLATES = [
    {
        'BACKEND': 'django.template.backends.django.DjangoTemplates',
        'DIRS': [os.path.join(BASE_DIR, "templates")],
        'APP_DIRS': True,
        'OPTIONS': {
            'context_processors': [
                'django.template.context_processors.request',
                'django.contrib.auth.context_processors.auth',
                'django.contrib.messages.context_processors.messages',
            ],
        },
    },
]

WSGI_APPLICATION = 'donapp.wsgi.application'

# Database
# Reemplaza con tus variables de entorno en el servidor real
DATABASES = {
    'default': {
        'ENGINE': 'django.db.backends.postgresql',
        'NAME': 'donapp_db',
        'USER': 'YOUR_DB_USER',
        'PASSWORD': 'YOUR_DB_PASSWORD',
        'HOST': 'localhost',
        'PORT': '5432',
    }
}

# Password validation
AUTH_PASSWORD_VALIDATORS = [
    {'NAME': 'django.contrib.auth.password_validation.UserAttributeSimilarityValidator'},
    {'NAME': 'django.contrib.auth.password_validation.MinimumLengthValidator'},
    {'NAME': 'django.contrib.auth.password_validation.CommonPasswordValidator'},
    {'NAME': 'django.contrib.auth.password_validation.NumericPasswordValidator'},
]

# Internationalization
LANGUAGE_CODE = 'es-cl'
TIME_ZONE = "America/Santiago"
USE_I18N = True
USE_TZ = True

# Static & Media Files
STATIC_URL = '/static/'
STATICFILES_DIRS = [os.path.join(BASE_DIR, "static")]
MEDIA_URL = '/media/'
MEDIA_ROOT = BASE_DIR / 'media'

DEFAULT_AUTO_FIELD = 'django.db.models.BigAutoField'

# DRF & JWT
REST_FRAMEWORK = {
    'DEFAULT_AUTHENTICATION_CLASSES': [
        'rest_framework_simplejwt.authentication.JWTAuthentication',
    ],
    'DEFAULT_PERMISSION_CLASSES': [
        'rest_framework.permissions.IsAuthenticated',
    ],
}

SIMPLE_JWT = {
    'ACCESS_TOKEN_LIFETIME': timedelta(minutes=60),
    'REFRESH_TOKEN_LIFETIME': timedelta(days=1),
    'SIGNING_KEY': SECRET_KEY,
}

# Email Config (Sanitizado)
EMAIL_BACKEND = "django.core.mail.backends.smtp.EmailBackend"
EMAIL_HOST = "smtp.gmail.com"
EMAIL_PORT = 587
EMAIL_USE_TLS = True
EMAIL_HOST_USER = 'YOUR_EMAIL@sansano.usm.cl'
EMAIL_HOST_PASSWORD = 'YOUR_APP_SPECIFIC_PASSWORD'
DEFAULT_FROM_EMAIL = "Donapp <YOUR_EMAIL@sansano.usm.cl>"

# Externals (Sanitizado)
ONESIGNAL_APP_ID = "YOUR_ONESIGNAL_APP_ID"
ONESIGNAL_API_KEY = "YOUR_ONESIGNAL_REST_API_KEY"

RUNPOD_API_KEY = os.getenv("RUNPOD_API_KEY", "")
RUNPOD_ENDPOINT_ID = os.getenv("RUNPOD_ENDPOINT_ID", "")

QDRANT_HOST = "localhost"
QDRANT_PORT = 6333

# Celery
CELERY_BROKER_URL = "redis://localhost:6379/0"
CELERY_TIMEZONE = "America/Santiago"



