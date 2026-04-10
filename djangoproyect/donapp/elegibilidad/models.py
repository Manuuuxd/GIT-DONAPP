from django.db import models
from django.contrib.auth.models import User

class FormularioElegibilidad(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    edad = models.PositiveIntegerField()
    peso = models.PositiveIntegerField()
    sueño_horas = models.PositiveIntegerField()
    comida_reciente = models.PositiveIntegerField()
    meses_ultima_donacion = models.PositiveIntegerField()
    tiene_documento = models.BooleanField()
    genero = models.CharField(max_length=10)
    criterios_consultar = models.JSONField()
    criterios_exclusion = models.JSONField()
    resultado = models.CharField(max_length=100)
    creado_en = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.username} - {self.resultado}"