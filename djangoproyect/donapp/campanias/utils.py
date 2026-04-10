# campanias/utils.py
from django.core.mail import send_mail
from django.conf import settings
import requests, json

ONESIGNAL_APP_ID = settings.ONESIGNAL_APP_ID
ONESIGNAL_API_KEY = settings.ONESIGNAL_API_KEY

import requests
import json
from django.conf import settings

ONESIGNAL_APP_ID = settings.ONESIGNAL_APP_ID
ONESIGNAL_API_KEY = settings.ONESIGNAL_API_KEY

def enviar_push_masivo(onesignal_player_ids, titulo, mensaje, envio_id=None):
    if not onesignal_player_ids:
        return False

    url = "https://onesignal.com/api/v1/notifications"
    headers = {
        "Authorization": f"Basic {ONESIGNAL_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "app_id": ONESIGNAL_APP_ID,
        "include_player_ids": onesignal_player_ids,
        "headings": {"en": titulo},
        "contents": {"en": mensaje},
        "buttons": [
            {"id": "agendar", "text": "Agendar ahora"},
            {"id": "descartar", "text": "No por ahora"},
        ],
        "data": {
            "envio_id": envio_id
        }
    }
    try:
        resp = requests.post(url, data=json.dumps(payload), headers=headers, timeout=10)
        resp.raise_for_status()
        return True
    except requests.exceptions.RequestException:
        return False


def enviar_email(user, mensaje, titulo):
    if not user.email:
        print(f"[EMAIL SKIP] Usuario {user.username} no tiene email")
        return False
    try:
        send_mail(
            subject=titulo,
            message=mensaje,
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[user.email],
            fail_silently=False
        )
        print(f"[EMAIL OK] Enviado a {user.email}")
        return True
    except Exception as e:
        print(f"[EMAIL ERROR] No se pudo enviar a {user.email}: {e}")
        return False

