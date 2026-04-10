from django.contrib.auth.models import User
from django.db import models
from datetime import timedelta
from django.contrib.postgres.fields import ArrayField  # 👈 para preferencias múltiples

class UserProfile(models.Model):
    SEXO_CHOICES = [
        ('M', 'Masculino'),
        ('F', 'Femenino'),
        ('O', 'Otro'),
    ]
    TIPO_SANGRE_CHOICES = [
        ('A+', 'A+'),
        ('A-', 'A-'),
        ('B+', 'B+'),
        ('B-', 'B-'),
        ('AB+', 'AB+'),
        ('AB-', 'AB-'),
        ('O+', 'O+'),
        ('O-', 'O-')
    ]
    PREFERENCIAS_CHOICES = [
        ('push', 'Notificaciones Push'),
        ('whatsapp', 'WhatsApp'),
        ('correo', 'Correo Electrónico'),
    ]

    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name='profile')
    sexo = models.CharField(max_length=1, choices=SEXO_CHOICES)
    apto_para_donar = models.BooleanField(default=False)
    fecha_ultima_donacion = models.DateField(null=True, blank=True)
    tipo_sangre = models.CharField(max_length=3, choices=TIPO_SANGRE_CHOICES, null=True, blank=True)
    edad = models.PositiveIntegerField(null=True, blank=True)

    region = models.CharField(max_length=100, blank=True)
    provincia = models.CharField(max_length=100, blank=True)
    comuna = models.CharField(max_length=100, blank=True)

    xp = models.PositiveIntegerField(default=0)
    nivel = models.PositiveIntegerField(default=1)

    is_admin = models.BooleanField(default=False)

    amigos = models.ManyToManyField('self', blank=True, symmetrical=True)

    # Comunicación multicanal
    onesignal_player_id = models.CharField(max_length=255, null=True, blank=True)
    telefono = models.CharField(max_length=15, null=True, blank=True)
    preferencias_notificacion = ArrayField(
        models.CharField(max_length=20, choices=PREFERENCIAS_CHOICES),
        default=list,  # 🔥 guarda [] en la DB por defecto
        blank=True
    )

    def proxima_donacion(self):
        if not self.fecha_ultima_donacion:
            return None
        dias_espera = 120 if self.sexo == 'F' else 90
        return self.fecha_ultima_donacion + timedelta(days=dias_espera)

    def actualizar_nivel(self):
        niveles = [
            (1, 0),
            (2, 50),
            (3, 120),
            (4, 200),
            (5, 300),
            (6, 450),
            (7, 600),
            (8, 800),
            (9, 1050),
            (10, 1400),
        ]
        for n, req_xp in reversed(niveles):
            if self.xp >= req_xp:
                self.nivel = n
                break
        self.save()

    def nombre_nivel(self):
        nombres = {
            1: "Donante Novato",
            2: "Aprendiz de Sangre",
            3: "Candidato Ideal",
            4: "Explorador Hemático",
            5: "Aliado del Banco",
            6: "Experto en Componentes",
            7: "Embajador de la Vida",
            8: "Guardián del Frigorífico",
            9: "Mentor de Donantes",
            10: "Héroe Universal 🦸‍♂️🦸‍♀️"
        }
        return nombres.get(self.nivel, "Desconocido")

    def __str__(self):
        return self.user.username

class PasswordResetToken(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    token = models.CharField(max_length=128, unique=True)
    created_at = models.DateTimeField(auto_now_add=True)
    expires_at = models.DateTimeField()

class FriendRequest(models.Model):
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_requests')
    receiver = models.ForeignKey(User, on_delete=models.CASCADE, related_name='received_requests')
    created_at = models.DateTimeField(auto_now_add=True)
    accepted = models.BooleanField(default=False)

    class Meta:
        unique_together = ('sender', 'receiver')

    def __str__(self):
        return f"{self.sender.username} → {self.receiver.username} ({'Aceptada' if self.accepted else 'Pendiente'})"

class UserAvatar(models.Model):
    user = models.OneToOneField(User, on_delete=models.CASCADE)
    skin_color = models.IntegerField(default=0xFFF4D1B5)
    shirt_color = models.IntegerField(default=0xFF4DA1E5)
    accessory = models.CharField(max_length=20, default="none")

    def __str__(self):
        return f"Avatar de {self.user.username}"
