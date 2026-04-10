from django.contrib import admin
from django.urls import path, include
from django.conf import settings
from django.conf.urls.static import static

from rest_framework_simplejwt.views import (
    TokenObtainPairView,
    TokenRefreshView,
)


from usuarios.views import CustomTokenObtainPairView
urlpatterns = [
    path('admin/', admin.site.urls),

    #JWT
    path('api/token/', CustomTokenObtainPairView.as_view(), name='token_obtain_pair'),      # Para obtener access y refresh
    path('api/token/refresh/', TokenRefreshView.as_view(), name='token_refresh'),     # Para refrescar token

    #apps
    path('api/users/', include('usuarios.urls')),
    path('api/trivia/', include('trivia.urls')),
    path('api/elegibilidad/', include('elegibilidad.urls')),
    path('api/campanias/', include('campanias.urls')),
    path('api/logros/', include('logros.urls')),
    # appointments
    path('api/appointments/', include('appointments.urls')),


    path('api/survey/', include('survey.urls')),
    path('api/Whatsapp/', include('Whatsapp.urls')),
    # Para pruebas de correo

    #chats
    path('api/chat/', include('chats.urls')),

    # desafios
    path('api/desafios/', include('desafios.urls')),

    # historias
    path('api/historias/', include('historias.urls')),


    
]

# --- AÑADE ESTA LÍNEA AL FINAL ---
# Esto solo funciona en modo DEBUG (desarrollo)
if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)