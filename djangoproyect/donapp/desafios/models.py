from django.db import models
from django.contrib.auth.models import User
from django.utils import timezone


class DesafioSemanal(models.Model):
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField()
    # --- CAMBIOS AQUÍ ---
    # Añadimos más opciones para tener desafíos más variados
    tipo = models.CharField(max_length=50, choices=[
        ("donacion", "Donación"),
        ("asistencia", "Asistencia a campaña"),
        ("abrir_app", "Apertura de la app"),
        ("trivia", "Responder Trivia"),
        ("compartir", "Compartir en Redes"),
        ("jugar", "Jugar Minijuego"),
        ("ver_campana", "Ver una Campaña"),
    ])
    fecha_inicio = models.DateField()
    fecha_fin = models.DateField()

    def __str__(self):
        return self.nombre


class DesafioUsuario(models.Model):
    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    desafio = models.ForeignKey(DesafioSemanal, on_delete=models.CASCADE)
    estado = models.CharField(max_length=20, choices=[
        ("pendiente", "Pendiente"),
        ("completado", "Completado"),
        ("fallido", "Fallido"),
    ], default="pendiente")
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.usuario.username} - {self.desafio.nombre} ({self.estado})"


class Insignia(models.Model):
    usuario = models.ForeignKey(User, on_delete=models.CASCADE, related_name="insignias")
    nombre = models.CharField(max_length=100)
    descripcion = models.TextField(blank=True)
    icono = models.ImageField(upload_to="insignias/")
    fecha_obtenida = models.DateTimeField(default=timezone.now)

    def __str__(self):
        return f"{self.nombre} - {self.usuario.username}"

