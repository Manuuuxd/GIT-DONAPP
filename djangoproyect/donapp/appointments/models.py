# Archivo: models.py (CORREGIDO)

from django.db import models
from django.conf import settings
from django.contrib.auth.models import User 

class DonationCenter(models.Model):
    name = models.CharField(max_length=150)
    address = models.CharField(max_length=255)
    comuna = models.CharField(max_length=100)
    phone = models.CharField(max_length=20, blank=True, null=True)

    def __str__(self):
        return f"{self.name} - {self.comuna}"


class Appointment(models.Model):
    STATUS_CHOICES = [
        ('scheduled', 'Scheduled'),
        ('cancelled', 'Cancelled'),
        ('completed', 'Completed'),
    ]

    # --- 🌟 CAMBIO AQUÍ 🌟 ---
    # Permitimos que el usuario sea nulo (para citas de invitados)
    user = models.ForeignKey(User, on_delete=models.CASCADE, null=True, blank=True)
    # --- FIN CAMBIO ---

    rut = models.CharField(max_length=12)
    email = models.EmailField()
    date = models.DateField()
    time = models.TimeField()
    center = models.ForeignKey(DonationCenter, on_delete=models.CASCADE)
    status = models.CharField(max_length=10, choices=STATUS_CHOICES, default='scheduled')
    cancellation_reason = models.TextField(blank=True, null=True)

    def __str__(self):
        # Maneja el caso de que no haya usuario
        username = self.user.username if self.user else "Invitado"
        return f"{username} - {self.center.name} - {self.date} {self.time}"

class Cancellation(models.Model):
    appointment = models.ForeignKey('Appointment', on_delete=models.CASCADE, related_name='cancellations')
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    reason = models.TextField()
    timestamp = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Cancelación de {self.user} - {self.appointment}"