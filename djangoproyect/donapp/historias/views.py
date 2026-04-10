# historias/views.py

from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from .models import Historia, LecturaUsuario
from .serializers import HistoriaSerializer, LecturaUsuarioSerializer
# ▼▼▼ IMPORTAMOS EL MODELO DE INSIGNIA DE LA OTRA APP ▼▼▼
from desafios.models import Insignia

class HistoriaViewSet(viewsets.ReadOnlyModelViewSet):
    """
    Un ViewSet para listar y obtener historias.
    """
    queryset = Historia.objects.all()
    serializer_class = HistoriaSerializer

    @action(detail=False, methods=['get'])
    def siguiente(self, request):
        """
        Algoritmo para seleccionar la próxima historia para el usuario.
        Cumple con CA01 y CA03.
        """
        usuario = request.user
        
        # --- (CA01) CONEXIÓN CON TU MODELO UserProfile ---
        try:
            # Accedemos directamente al perfil del usuario y obtenemos su tipo de sangre
            valor_formulario_usuario = usuario.profile.tipo_sangre
            if not valor_formulario_usuario:
                # Si el campo está vacío, usamos un tag general
                valor_formulario_usuario = "general"
        except AttributeError:
            # Si el usuario no tiene perfil (poco probable, pero seguro)
            valor_formulario_usuario = "general"

        # (CA03) Excluir historias que el usuario marcó como "No leer de nuevo"
        historias_excluidas_ids = LecturaUsuario.objects.filter(
            usuario=usuario,
            no_mostrar_de_nuevo=True
        ).values_list('historia_id', flat=True)

        queryset = Historia.objects.exclude(id__in=historias_excluidas_ids)
        
        # Excluir historias ya leídas para la sugerencia principal
        historias_leidas_ids = LecturaUsuario.objects.filter(
            usuario=usuario,
            completada=True
        ).values_list('historia_id', flat=True)
        
        queryset = queryset.exclude(id__in=historias_leidas_ids)

        # (CA01) Intentar encontrar una historia que coincida con el tipo de sangre
        historia_sugerida = queryset.filter(tag_formulario=valor_formulario_usuario).first()

        if not historia_sugerida:
            # Si no hay coincidencia, tomar cualquier otra historia que no haya leído
            historia_sugerida = queryset.first()

        if not historia_sugerida:
            return Response({"detail": "No hay nuevas historias disponibles."}, status=status.HTTP_404_NOT_FOUND)

        serializer = self.get_serializer(historia_sugerida)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def interactuar(self, request, pk=None):
        """
        Registra la interacción de un usuario con una historia.
        Cumple con CA02 y CA03.
        """
        historia = self.get_object()
        usuario = request.user
        
        completada = request.data.get('completada')
        no_mostrar = request.data.get('no_mostrar_de_nuevo')

        lectura, created = LecturaUsuario.objects.get_or_create(
            usuario=usuario,
            historia=historia
        )

        if completada is not None and completada and not lectura.completada:
            lectura.completada = True
            
            # --- (CA02) CREACIÓN DEL LOGRO/INSIGNIA ---
            nombre_insignia = f"Lector de: {historia.titulo}"
            # Verificamos que no exista ya para evitar duplicados
            if not Insignia.objects.filter(usuario=usuario, nombre=nombre_insignia).exists():
                Insignia.objects.create(
                    usuario=usuario,
                    nombre=nombre_insignia,
                    descripcion="Por leer una historia inspiradora.",
                    # Puedes crear un ícono genérico para las historias
                    icono="insignias/historia_leida.png" 
                )

        if no_mostrar is not None:
            lectura.no_mostrar_de_nuevo = no_mostrar
        
        lectura.save()
        
        return Response(LecturaUsuarioSerializer(lectura).data, status=status.HTTP_200_OK)