from rest_framework import generics, permissions
from .models import FormularioElegibilidad
from .serializers import FormularioElegibilidadSerializer
from datetime import timedelta
from django.utils import timezone
from campanias.tasks import enviar_aviso_expiracion_criterio_excluyente
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework import status, permissions

class FormularioElegibilidadCreateAPI(generics.CreateAPIView):
    serializer_class = FormularioElegibilidadSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)


# campanias/views.py
class ProgramarNotificacionAPIView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        criterios = request.data.get('criterios_exclusion', []) or []
        genero = request.data.get('genero')
        fecha_deteccion = request.data.get('fecha_deteccion')
        fecha_ultima_donacion = request.data.get('fecha_ultima_donacion')
        forzar_envio_ahora = bool(request.data.get('forzar_envio_ahora', False))

        enviar_aviso_expiracion_criterio_excluyente.delay(
            user_id=request.user.id,
            criterios=criterios,
            genero=genero,
            fecha_deteccion=fecha_deteccion,
            fecha_ultima_donacion=fecha_ultima_donacion,
            forzar_envio_ahora=forzar_envio_ahora,
        )
        print("/n Aquí /n")
        return Response({"message": "Notificación programada correctamente"}, status=status.HTTP_201_CREATED)
