from django.urls import path
from .views import FormularioElegibilidadCreateAPI
from .views import ProgramarNotificacionAPIView


urlpatterns = [
    path('elegibilidad-donacion/', FormularioElegibilidadCreateAPI.as_view(), name='crear-elegibilidad'),
    path('notificaciones/programar/', ProgramarNotificacionAPIView.as_view(), name='programar_notificacion'),
]