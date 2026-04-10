# historias/models.py

from django.db import models
from django.contrib.auth.models import User

class Historia(models.Model):
    titulo = models.CharField(max_length=200)
    contenido = models.TextField()
    # Campo para el algoritmo condicional (CA01)
    tag_formulario = models.CharField(
        max_length=50,
        blank=True,
        null=True,
        help_text="Coincide con un valor del formulario inicial del usuario (ej: 'grupo_sanguineo_O+')"
    )

    def __str__(self):
        return self.titulo

class LecturaUsuario(models.Model):
    """
    Rastrea la interacción de un usuario con una historia.
    """
    usuario = models.ForeignKey(User, on_delete=models.CASCADE)
    historia = models.ForeignKey(Historia, on_delete=models.CASCADE)
    completada = models.BooleanField(default=False)
    no_mostrar_de_nuevo = models.BooleanField(default=False)
    fecha_lectura = models.DateTimeField(auto_now_add=True)

    class Meta:
        # Asegura que no haya entradas duplicadas para el mismo usuario e historia
        unique_together = ('usuario', 'historia')

    def __str__(self):
        return f"{self.usuario.username} - {self.historia.titulo}"