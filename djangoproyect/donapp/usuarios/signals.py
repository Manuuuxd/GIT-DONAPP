from django.contrib.auth.signals import user_logged_in
from django.dispatch import receiver
from threading import Timer
from .email_utils import enviar_recordatorio_con_imagen

@receiver(user_logged_in)
def enviar_recordatorio_despues_login(sender, request, user, **kwargs):
    # Lanzar envío de correo 2 minutos después
    Timer(120, enviar_recordatorio_con_imagen, args=[user.email, user.get_full_name() or user.username]).start()
