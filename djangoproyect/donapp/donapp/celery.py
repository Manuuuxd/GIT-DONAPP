import os
from celery import Celery

from celery.schedules import crontab

CELERY_BEAT_SCHEDULE = {
    "enviar-recordatorios-donacion": {
        "task": "campanias.tasks.enviar_recordatorios_donacion",
        "schedule": crontab(hour=9, minute=0),  # todos los días a las 09:00
    },
}



os.environ.setdefault("DJANGO_SETTINGS_MODULE", "donapp.settings")

app = Celery("donapp")
app.config_from_object("django.conf:settings", namespace="CELERY")
app.autodiscover_tasks()


app.conf.beat_schedule.update({
    "recordatorio-citas-manana": {
        "task": "appointments.tasks.enviar_recordatorio_citas_manana",
        "schedule": crontab(hour=23, minute=38),  # hora local de app.conf.timezone
    },
})