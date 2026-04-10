from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Campania, EnvioCampania

class CampaniaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Campania
        fields = '__all__'


class DestinatarioSerializer(serializers.ModelSerializer):
    nombre = serializers.CharField(source="first_name", read_only=True)
    apellido = serializers.CharField(source="last_name", read_only=True)
    email = serializers.EmailField(read_only=True)
    telefono = serializers.CharField(source="profile.telefono", read_only=True)
    tipo_sangre = serializers.CharField(source="profile.tipo_sangre", read_only=True)
    rh = serializers.CharField(source="profile.rh", read_only=True)
    preferencias_notificacion = serializers.ListField(
        source="profile.preferencias_notificacion", read_only=True
    )

    class Meta:
        model = User
        fields = [
            "id", "username", "nombre", "apellido", "email", "telefono",
            "tipo_sangre", "rh", "preferencias_notificacion"
        ]


class EnvioCampaniaSerializer(serializers.ModelSerializer):
    class Meta:
        model = EnvioCampania
        fields = "__all__"

