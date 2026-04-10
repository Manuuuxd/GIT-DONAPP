from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class Campania(models.Model):
    ESTADOS = [
        ('activa', 'Activa'),
        ('cerrada', 'Cerrada'),
        ('borrador', 'Borrador'),
        ('cancelada', 'Cancelada'),
        ('programada', 'Programada'),
    ]

    nombre = models.CharField(max_length=255)
    direccion = models.TextField()
    comuna = models.CharField(max_length=100)
    latitud = models.FloatField(null=True, blank=True)
    longitud = models.FloatField(null=True, blank=True)
    fecha = models.DateField()
    horario = models.CharField(max_length=100)
    grupo_sanguineo = models.CharField(max_length=3, choices=[
        ('A', 'A'), ('B', 'B'), ('AB', 'AB'), ('O', 'O')
    ])
    rh = models.CharField(max_length=1, choices=[('+', '+'), ('-', '-')], blank=True, null=True)
    foto = models.ImageField(upload_to="campanias/", blank=True, null=True)
    estado = models.CharField(max_length=20, choices=ESTADOS, default="borrador")
    programado_para = models.DateTimeField(blank=True, null=True)  # nuevo
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.nombre


class EnvioCampania(models.Model):
    REACCIONES = [
        ("feliz", "😀"),
        ("sonriente", "🙂"),
        ("neutro", "😐"),
        ("fruncido", "🙁"),
        ("enojado", "😡"),
        ("agendar", "Agendar"),
        ("opt_out", "No por ahora"),
        ("error_envio", "Error de envío"),
    ]

    campania = models.ForeignKey('Campania', on_delete=models.CASCADE)
    destinatario = models.ForeignKey(User, on_delete=models.CASCADE)
    enviado_email = models.BooleanField(default=False)
    enviado_push = models.BooleanField(default=False)
    timestamp = models.DateTimeField(auto_now_add=True)
    recibido_en = models.DateTimeField(blank=True, null=True)  # marca de recepción
    reaccion = models.CharField(max_length=20, choices=REACCIONES, blank=True, null=True)

    def __str__(self):
        return f"{self.campania.nombre} → {self.destinatario.username}"

