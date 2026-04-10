# historias/serializers.py

from rest_framework import serializers
from .models import Historia, LecturaUsuario

class HistoriaSerializer(serializers.ModelSerializer):
    class Meta:
        model = Historia
        fields = ['id', 'titulo', 'contenido', 'tag_formulario']

class LecturaUsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = LecturaUsuario
        fields = ['id', 'usuario', 'historia', 'completada', 'no_mostrar_de_nuevo']