from rest_framework import serializers
from .models import DesafioSemanal, DesafioUsuario, Insignia

class DesafioSemanalSerializer(serializers.ModelSerializer):
    class Meta:
        model = DesafioSemanal
        fields = "__all__"


class DesafioUsuarioSerializer(serializers.ModelSerializer):
    # --- CAMBIOS AQUÍ ---
    # Hacemos que el campo 'usuario' sea de solo lectura.
    # El servidor lo llenará automáticamente con el usuario de la sesión actual.
    usuario = serializers.PrimaryKeyRelatedField(read_only=True)

    class Meta:
        model = DesafioUsuario
        # Especificamos los campos explícitamente para asegurar que 'usuario'
        # no sea requerido en la entrada del cliente (POST/PUT).
        fields = ['id', 'usuario', 'desafio', 'estado', 'fecha']
        read_only_fields = ['usuario', 'fecha']


class InsigniaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Insignia
        fields = "__all__"
