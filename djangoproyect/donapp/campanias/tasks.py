"""Tasks de campañas y notificaciones."""

from __future__ import annotations  # 👈 Debe ir aquí, antes de cualquier otro import o código

from celery import shared_task
from django.contrib.auth.models import User
from django.utils import timezone
from .models import Campania, EnvioCampania
from .serializers import EnvioCampaniaSerializer
from .utils import enviar_push_masivo, enviar_email
from datetime import timedelta

from celery import shared_task
from django.utils import timezone
from django.contrib.auth.models import User
from .models import Campania, EnvioCampania
from .serializers import EnvioCampaniaSerializer
from .utils import enviar_push_masivo, enviar_email

from appointments.models import Appointment
from django.db.models import Q


@shared_task(bind=True, name="enviar_campania_task")
def enviar_campania_task(self, campania_id, titulo, mensaje):
    try:
        campania = Campania.objects.get(id=campania_id)
    except Campania.DoesNotExist:
        return f"Campania {campania_id} no existe"

    filtros = {"profile__apto_para_donar": True}
    if campania.grupo_sanguineo:
        if campania.rh:
            filtros["profile__tipo_sangre"] = f"{campania.grupo_sanguineo}{campania.rh}"
        else:
            filtros["profile__tipo_sangre__startswith"] = campania.grupo_sanguineo

    usuarios = User.objects.filter(profile__isnull=False, **filtros)
    resultados_envio = []
    hoy = timezone.now().date()

    for usuario in usuarios:
        if EnvioCampania.objects.filter(destinatario=usuario, timestamp__date=hoy).count() >= 3:
            continue

        envio = EnvioCampania.objects.create(
            campania=campania,
            destinatario=usuario
        )

        push_enviado = False
        email_enviado = False

        if usuario.profile.onesignal_player_id:
            push_enviado = enviar_push_masivo(
                [usuario.profile.onesignal_player_id],
                titulo,
                mensaje,
                envio.id  # 🔑 mandamos el ID único
            )
        if "correo" in usuario.profile.preferencias_notificacion:
            email_enviado = enviar_email(usuario, mensaje, titulo)

        envio.enviado_push = push_enviado
        envio.enviado_email = email_enviado
        envio.save()

        resultados_envio.append(EnvioCampaniaSerializer(envio).data)

    campania.estado = "activa"
    campania.save()

    return {
        "campania_id": campania.id,
        "total_envios": len(resultados_envio),
        "detalles_envios": resultados_envio
    }

@shared_task(bind=True)
def enviar_recordatorios_donacion():
    """
    Enviar recordatorios automáticos según última fecha de donación y género.
    Corre todos los días a las 09:00 (configurar en Celery Beat).
    """
    hoy = timezone.now().date()
    usuarios = User.objects.filter(profile__fecha_ultima_donacion__isnull=False)

    for user in usuarios:
        fecha = user.profile.fecha_ultima_donacion
        genero = user.profile.sexo

        # Saltar si no hay fecha válida
        if not fecha:
            continue

        # Reglas de días
        if genero == "M":  # hombre
            dias = 90
        elif genero == "F":  # mujer
            dias = 120
        else:  # no definido / no binario
            dias = 120

        proxima = fecha + timedelta(days=dias)

        if proxima == hoy:
            titulo = "¡Ya puedes volver a donar!"
            mensaje = (
                "Según lo que indicas puedes donar desde hoy. "
                "¿Quieres agendar tu hora?"
            )

            if user.profile.onesignal_player_id:
                enviar_push_masivo([user.profile.onesignal_player_id], titulo, mensaje)
            if "correo" in (user.profile.preferencias_notificacion or []):
                enviar_email(user, mensaje, titulo)


# campanias/tasks.py
from celery import shared_task
from datetime import datetime, timedelta
from dateutil.relativedelta import relativedelta
from django.conf import settings
from django.utils import timezone
from django.contrib.auth import get_user_model
import requests

User = get_user_model()

# --- CONFIG OneSignal ---
ONESIGNAL_APP_ID = getattr(settings, "ONESIGNAL_APP_ID", None)
ONESIGNAL_API_KEY = getattr(settings, "ONESIGNAL_API_KEY", None)

# Si guardas el/los device/player IDs de OneSignal en el perfil del usuario, ajusta este accessor.
def _get_user_player_ids(user: User) -> list[str]:
    """
    Devuelve los OneSignal player IDs (device ids) del usuario.
    Ajusta esto a tu modelo. Ejemplos:
      - user.profile.onesignal_player_id
      - [d.player_id for d in user.devices.all()]
    """
    try:
        # ejemplo: permitir lista o único string
        pid = getattr(user, "onesignal_player_id", None) or getattr(user, "player_id", None)
        if isinstance(pid, str):
            return [pid]
        if isinstance(pid, (list, tuple)):
            return list(pid)
        # o si lo llevas en profile:
        prof = getattr(user, "profile", None)
        if prof and getattr(prof, "onesignal_player_id", None):
            return [prof.onesignal_player_id]
    except Exception:
        pass
    return []

# --- Lógica de plazos por criterio excluyente ---
INDEFINIDOS = {
    "Se ha inyectado drogas ilegales.",
}

# Mapeo a deltas aproximados/razonables para Chile (ajústalo a tu norma/criterios clínicos)
CRITERIO_A_DELTA = {
    "Tomó antibióticos en los últimos 7 días.": timedelta(days=7),
    "Tuvo diarrea en los últimos 14 días.": timedelta(days=14),
    "Está embarazada o tuvo parto o aborto en los últimos 6 meses.": relativedelta(months=+6),
    "Se realizó endoscopía, colonoscopía, tatuajes, piercings, perforaciones o acupuntura en los últimos 6 meses.": relativedelta(months=+6),
    # Riesgo sexual típico (ajustable):
    "Tiene pareja sexual nueva y mantienen relaciones sexuales hace menos de 6 meses.": relativedelta(months=+6),
    "Tuvo más de una pareja sexual en los últimos 6 meses.": relativedelta(months=+6),
    "Tuvo relaciones sexuales con personas que ejercen el comercio sexual en los últimos 12 meses.": relativedelta(months=+12),
    # Malaria (según protocolos suele ser >1–3 años post-salida; aquí 3 años conservador):
    "Ha residido en zonas endémicas de malaria por más de 6 meses en cualquier periodo de su vida.": relativedelta(years=+3),
}

def _coerce_to_aware(dt_str: str | None) -> datetime | None:
    if not dt_str:
        return None
    # Acepta ISO con o sin tz; si es naive la vuelve aware en tz actual
    try:
        dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
    except Exception:
        return None
    if timezone.is_naive(dt):
        return timezone.make_aware(dt, timezone.get_current_timezone())
    return dt.astimezone(timezone.get_current_timezone())

def _sumar_delta(base: datetime, delta) -> datetime:
    # delta puede ser timedelta o relativedelta
    if isinstance(delta, relativedelta):
        return base + delta
    return base + delta  # timedelta

def _max_dt(a: datetime, b: datetime) -> datetime:
    return a if a >= b else b

@shared_task(bind=True)
def enviar_aviso_expiracion_criterio_excluyente(
    self,
    user_id: int,
    criterios: list[str] | None = None,
    genero: str | None = None,
    fecha_deteccion: str | None = None,
    fecha_ultima_donacion: str | None = None,
    forzar_envio_ahora: bool = False,
):
    """
    Calcula la fecha en que expiran los criterios excluyentes (y la ventana mínima por última donación)
    y programa un push para ese momento. Si `forzar_envio_ahora=True`, envía el push al instante.
    """
    criterios = criterios or []
    genero = (genero or "").strip()
    ahora = timezone.now()

    # Log de entrada para diagnóstico
    print(f"[PLAN] user={user_id} criterios={criterios} genero={genero!r} "
          f"fecha_deteccion={fecha_deteccion!r} fecha_ultima_donacion={fecha_ultima_donacion!r} "
          f"forzar={forzar_envio_ahora}")

    # Helpers locales (si ya tienes _coerce_to_aware global, puedes usarlo)
    def _coerce_to_aware_local(dt_str: str | None):
        if not dt_str:
            return None
        try:
            dt = datetime.fromisoformat(dt_str.replace("Z", "+00:00"))
        except Exception:
            return None
        if timezone.is_naive(dt):
            return timezone.make_aware(dt, timezone.get_current_timezone())
        return dt.astimezone(timezone.get_current_timezone())

    def _sumar_delta(base_dt, delta):
        return base_dt + delta  # timedelta o relativedelta funcionan con +

    def _es_mujer(value: str) -> bool:
        v = (value or "").lower()
        # acepta "mujer", "f", "female"
        return v.startswith("muj") or v == "f" or v.startswith("fem")

    # Parseo de fechas
    dt_deteccion = _coerce_to_aware_local(fecha_deteccion) or ahora
    dt_ultima = _coerce_to_aware_local(fecha_ultima_donacion)

    # Si piden enviar ahora mismo, ignora cálculos y dispara
    if forzar_envio_ahora:
        user = User.objects.filter(id=user_id).first()
        if not user:
            print("[PLAN] user no existe")
            return
        titulo = "¡Te invitamos a repetir el formulario de donación. ¡Quizás ya cumplas los requisitos!"
        cuerpo = "Prueba forzada: notificando ahora mismo."
        print("[PLAN] forzado -> enviar_push_notificacion.delay(...)")
        enviar_push_notificacion.delay(user_id=user.id, title=titulo, message=cuerpo)
        return

    # Si hay criterios indefinidos, enviar mensaje informativo inmediato
    if any(c in INDEFINIDOS for c in criterios):
        user = User.objects.filter(id=user_id).first()
        if not user:
            print("[PLAN] user no existe (indefinido)")
            return
        titulo = "Información sobre tu elegibilidad"
        cuerpo = ("Algunos criterios marcados requieren evaluación clínica individual y no tienen "
                  "una fecha de expiración automática. Te contactaremos para orientarte.")
        print("[PLAN] criterio indefinido -> enviar_push_notificacion.delay(...)")
        enviar_push_notificacion.delay(user_id=user.id, title=titulo, message=cuerpo)
        return

    # Fecha objetivo: máximo entre (detección + delta criterio) y (última donación + months)
    fecha_objetivo = dt_deteccion
    for c in criterios:
        delta = CRITERIO_A_DELTA.get(c, timedelta(days=30))  # fallback 30 días
        fecha_c = _sumar_delta(dt_deteccion, delta)
        if fecha_c > fecha_objetivo:
            fecha_objetivo = fecha_c

    # Regla mínima por última donación (3M hombre, 4M mujer)
    if dt_ultima is not None:
        meses = 4 if _es_mujer(genero) else 3
        fecha_don = dt_ultima + relativedelta(months=+meses)
        if fecha_don > fecha_objetivo:
            fecha_objetivo = fecha_don

    # No programar en pasado: empuja 1 minuto
    if fecha_objetivo <= ahora:
        fecha_objetivo = ahora + timedelta(minutes=1)

    # Programar envío real
    user = User.objects.filter(id=user_id).first()
    if not user:
        print("[PLAN] user no existe (programación)")
        return

    titulo = "¡Te invitamos a repetir el formulario de donación. ¡Quizás ya cumplas los requisitos!"
    cuerpo = "Según tu última evaluación, ya se cumplió el tiempo de espera. Si te sientes bien, puedes agendar tu donación."

    print(f"[PLAN] programando push para {fecha_objetivo.isoformat()} user={user.id}")
    enviar_push_notificacion.apply_async(
        kwargs={"user_id": user.id, "title": titulo, "message": cuerpo},
        eta=fecha_objetivo
    )

@shared_task(bind=True, max_retries=3, default_retry_delay=60)
def enviar_push_notificacion(self, user_id: int, title: str, message: str):
    print(f"[PUSH] start user={user_id} title={title!r}")
    if not ONESIGNAL_APP_ID or not ONESIGNAL_API_KEY:
        print("[PUSH] Faltan credenciales OneSignal")
        raise RuntimeError("Faltan ONESIGNAL_APP_ID u ONESIGNAL_API_KEY en settings.")

    user = User.objects.filter(id=user_id).first()
    if not user:
        print("[PUSH] user no existe")
        return

    player_ids = _get_user_player_ids(user)
    print(f"[PUSH] user={user_id} player_ids={player_ids}")
    if not player_ids:
        raise self.retry(exc=RuntimeError("Usuario sin OneSignal player IDs"))

    url = "https://onesignal.com/api/v1/notifications"
    headers = {
        "Authorization": f"Basic {ONESIGNAL_API_KEY}",
        "Content-Type": "application/json",
    }
    payload = {
        "app_id": ONESIGNAL_APP_ID,
        "include_player_ids": player_ids,
        "headings": {"es": title, "en": title},
        "contents": {"es": message, "en": message},
        "android_channel_id": getattr(settings, "ONESIGNAL_ANDROID_CHANNEL_ID", None),
        "priority": 10,  # legacy < Android 8
        "collapse_id": "eligibility_ready",
        "data": {"type": "eligibility_ready"},
    }

    print(f"[PUSH] payload={payload}")
    try:
        r = requests.post(url, json=payload, headers=headers, timeout=10)
        print(f"[PUSH] OneSignal resp {r.status_code} {r.text}")
        if r.status_code >= 300:
            raise self.retry(exc=RuntimeError(f"OneSignal error {r.status_code}: {r.text}"))
    except requests.RequestException as e:
        print(f"[PUSH] exception {e}")
        raise self.retry(exc=e)


@shared_task(bind=True)
def enviar_recordatorio_citas_manana(self):
    # Usa el 'now' LOCAL y luego saca la fecha
    local_now = timezone.localtime(timezone.now())
    manana = (local_now + timedelta(days=1)).date()

    print(f"[CITAS] now_local={local_now.isoformat()} -> mañana={manana}")

    qs = (Appointment.objects
          .select_related("user", "center")
          .filter(Q(status="scheduled") & Q(date=manana)))

    print(f"[CITAS] encontradas={qs.count()} para fecha={manana}")

    for ap in qs:
        user = ap.user
        if not user:
            continue
        hora_txt = ap.time.strftime("%H:%M") if ap.time else ""
        centro = ap.center.name if ap.center else "tu centro de donación"
        titulo = "Recordatorio de tu cita 🗓️"
        mensaje = (f"Tienes una cita de donación mañana a las {hora_txt} en {centro}. "
                   "Si no puedes asistir, por favor reprograma.")
        enviar_push_notificacion.delay(user_id=user.id, title=titulo, message=mensaje)