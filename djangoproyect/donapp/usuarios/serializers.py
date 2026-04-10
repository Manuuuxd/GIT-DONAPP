from rest_framework import serializers
from django.contrib.auth.models import User
from .models import UserProfile,UserAvatar
from rest_framework.exceptions import ValidationError
from rest_framework_simplejwt.serializers import TokenObtainPairSerializer

# Serializer para mostrar el perfil completo
class UserProfileSerializer(serializers.ModelSerializer):
    proxima_donacion = serializers.SerializerMethodField()
    nombre_nivel = serializers.SerializerMethodField()
    nombre = serializers.CharField(source="user.first_name", read_only=True)
    user_id = serializers.IntegerField(source="user.id", read_only=True)
    tipo_sangre = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    telefono = serializers.CharField(allow_blank=True, allow_null=True, required=False)

    class Meta:
        model = UserProfile
        fields = [
            "id", "nombre", "sexo", "apto_para_donar",
            "region", "provincia", "comuna",
            "fecha_ultima_donacion", "xp", "nivel",
            "nombre_nivel", "proxima_donacion", "user_id",
            "tipo_sangre", "preferencias_notificacion", "telefono"
        ]

    def get_proxima_donacion(self, obj):
        prox = obj.proxima_donacion()
        return prox.isoformat() if prox else None

    def get_nombre_nivel(self, obj):
        return obj.nombre_nivel()


# Serializer para el usuario con su perfil
class UserSerializer(serializers.ModelSerializer):
    profile = UserProfileSerializer(read_only=True)

    class Meta:
        model = User
        fields = ['id', 'username', 'email', 'profile']


# Serializer de registro inicial con preferencias
class UserRegisterSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, min_length=6)
    sexo = serializers.ChoiceField(choices=[('M', 'Masculino'), ('F', 'Femenino')])
    telefono = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    preferencias_notificacion = serializers.ListField(
        child=serializers.ChoiceField(choices=[
            ('push', 'Notificaciones Push'),
            ('whatsapp', 'WhatsApp'),
            ('correo', 'Correo Electrónico')
        ]),
        write_only=True,
        required=True
    )

    class Meta:
        model = User
        fields = ["username", "email", "password", "sexo", "telefono", "preferencias_notificacion"]

    def validate_username(self, value):
        if User.objects.filter(username=value).exists():
            raise ValidationError("Este nombre de usuario ya está en uso.")
        return value

    def create(self, validated_data):
        preferencias = validated_data.pop("preferencias_notificacion", [])
        telefono = validated_data.pop("telefono", "")
        sexo = validated_data.pop("sexo")  # obligatorio

        user = User(username=validated_data["username"], email=validated_data.get("email", ""))
        user.set_password(validated_data["password"])
        try:
            user.save()
            UserProfile.objects.create(
                user=user,
                preferencias_notificacion=preferencias,
                telefono=telefono,
                sexo=sexo,
                apto_para_donar=True,
                region="",
                provincia="",
                comuna=""
            )
        except Exception as e:
            raise ValidationError({"detail": str(e)})
        return user

class CustomTokenObtainPairSerializer(TokenObtainPairSerializer):
    @classmethod
    def get_token(cls, user):
        token = super().get_token(user)

        # 👇 Add custom fields here
        token['username'] = user.username
        token['email'] = user.email
        token['is_admin'] = user.is_staff  # or user.is_superuser
        token['first_name'] = user.first_name
        token['last_name'] = user.last_name

        return token

# Serializer para actualizar preferencias y resto del perfil después
class UserProfileUpdateSerializer(serializers.ModelSerializer):
    preferencias_notificacion = serializers.ListField(
        child=serializers.ChoiceField(choices=[
            ('push', 'Notificaciones Push'),
            ('whatsapp', 'WhatsApp'),
            ('correo', 'Correo Electrónico')
        ]),
        required=False
    )
    telefono = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    tipo_sangre = serializers.CharField(allow_blank=True, allow_null=True, required=False)
    # CORRECCIÓN: El nombre del campo debe ser onesignal_player_id
    onesignal_player_id = serializers.CharField(max_length=200, allow_blank=True, allow_null=True, required=False)  

    class Meta:
        model = UserProfile
        fields = [
            "sexo", "edad","apto_para_donar", "region", "provincia", "comuna",
            "tipo_sangre", "preferencias_notificacion", "telefono", "onesignal_player_id" # CORRECCIÓN: Usar onesignal_player_id
        ]


class UserProfileChoicesSerializer(serializers.Serializer):
    """
    Serializador para exponer las opciones de los campos del modelo UserProfile.
    """
    sexo = serializers.DictField(child=serializers.CharField())
    tipo_sangre = serializers.DictField(child=serializers.CharField())
    

from .models import FriendRequest, UserProfile

class FriendRequestSerializer(serializers.ModelSerializer):
    sender_username = serializers.CharField(source='sender.username', read_only=True)
    receiver_username = serializers.CharField(source='receiver.username', read_only=True)

    class Meta:
        model = FriendRequest
        fields = ['id', 'sender', 'sender_username', 'receiver', 'receiver_username', 'accepted', 'created_at']
        read_only_fields = ['id', 'created_at', 'accepted']


class UserAvatarSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAvatar
        fields = ["skin_color", "shirt_color", "accessory"]
