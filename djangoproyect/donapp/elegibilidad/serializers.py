from rest_framework import serializers
from .models import FormularioElegibilidad

class FormularioElegibilidadSerializer(serializers.ModelSerializer):
    class Meta:
        model = FormularioElegibilidad
        fields = '__all__'
        read_only_fields = ['user', 'creado_en']
