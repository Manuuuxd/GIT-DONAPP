from django.db import models
from django.conf import settings # Para obtener el modelo de usuario
from django.contrib.auth.models import User

# 1. Definición del Logro
class Achievement(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, help_text="Identificador único para la lógica.")
    description = models.TextField()
    required_count = models.IntegerField(default=1, help_text="Conteo necesario para desbloquear.")
    icon = models.ImageField(upload_to='achievement_icons/', null=True, blank=True)
    
    def __str__(self):
        return self.name

# 2. Progreso del Usuario (para logros de conteo)
class UserProgress(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    achievement_slug = models.CharField(max_length=100) # Usamos el slug del Achievement
    current_count = models.IntegerField(default=0)
    
    class Meta:
        unique_together = ('user', 'achievement_slug') # Un usuario solo puede tener un registro por logro.

# 3. Logros Desbloqueados por el Usuario
class UserAchievement(models.Model):
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE)
    achievement = models.ForeignKey(Achievement, on_delete=models.CASCADE)
    unlocked_at = models.DateTimeField(auto_now_add=True)
    
    class Meta:
        unique_together = ('user', 'achievement') # Un usuario solo puede desbloquear un logro una vez.

    def __str__(self):
        return f"{self.user.username} - {self.achievement.name}"

class Items(models.Model):
    name = models.CharField(max_length=100, unique=True)
    slug = models.SlugField(max_length=100, unique=True, help_text="Identificador único para el ítem.")
    value = models.IntegerField(default=0, help_text="Valor del ítem, si aplica.")
    description = models.TextField()
    icon = models.ImageField(upload_to='item_icons/', null=True, blank=True)
    canjeable = models.BooleanField(default=True, help_text="Indica si el ítem puede ser canjeado.")
    

    def __str__(self):
        return self.name
    

class UserItem(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    item_slug = models.CharField(max_length=64)  # Ej: 'xp_semanal', 'donacion_bono'
    cantidad = models.PositiveIntegerField(default=0)
    last_awarded = models.DateTimeField(auto_now=True)

    class Meta:
        unique_together = ('user', 'item_slug')
