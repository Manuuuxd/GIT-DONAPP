from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny, IsAuthenticated
from django.contrib.auth.models import User
from django.utils import timezone
from datetime import datetime
from django.db.models import Count
from django.shortcuts import get_object_or_404
from django.utils.timezone import make_aware


from .models import Campania, EnvioCampania
from .serializers import CampaniaSerializer, DestinatarioSerializer, EnvioCampaniaSerializer
from .tasks import enviar_campania_task  # Celery task

class CampaniaViewSet(viewsets.ModelViewSet):
    queryset = Campania.objects.all().order_by('-created_at')
    serializer_class = CampaniaSerializer

    def get_permissions(self):
        # Allow anyone to GET (list/retrieve)
        if self.action in ['list', 'retrieve']:
            return [AllowAny()]
        # Require auth for everything else (like enviar, previsualizar, reporte, etc.)
        return [IsAuthenticated()]

    @action(detail=True, methods=['get'])
    def destinatarios(self, request, pk=None):
        try:
            campania = self.get_object()
            filtros = {"profile__apto_para_donar": True}

            if campania.grupo_sanguineo:
                if campania.rh:
                    filtros["profile__tipo_sangre"] = f"{campania.grupo_sanguineo}{campania.rh}"
                else:
                    filtros["profile__tipo_sangre__startswith"] = campania.grupo_sanguineo

            usuarios = User.objects.filter(profile__isnull=False, **filtros).exclude(
                enviocampania__campania=campania,
                enviocampania__reaccion='opt_out'
            )

            serializer = DestinatarioSerializer(usuarios, many=True)
            return Response({"destinatarios": serializer.data, "total": usuarios.count()})
        
        except Exception as e:
            return Response({"error": str(e)}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


    @action(detail=True, methods=['post'])
    def enviar(self, request, pk=None):
        campania = self.get_object()
        titulo = request.data.get("titulo")
        mensaje = request.data.get("mensaje")
        programado_para = request.data.get("programado_para")  # "YYYY-MM-DD HH:MM"

        if not titulo or not mensaje:
            return Response({"error": "Debe enviar un título y un mensaje"}, status=400)

        # Envío programado
        if programado_para:
            dt = make_aware(datetime.fromisoformat(programado_para))
            campania.programado_para = dt
            campania.estado = "programada"
            campania.save()

            enviar_campania_task.apply_async(
                args=[campania.id, titulo, mensaje],
                eta=dt
            )
            return Response({"status": "programado", "programado_para": dt})

        # Envío inmediato vía Celery
        enviar_campania_task.delay(campania.id, titulo, mensaje)
        campania.estado = "activa"
        campania.save()
        return Response({"status": "enviado_inmediatamente"})

    @action(detail=True, methods=["post"])
    def previsualizar(self, request, pk=None):
        campania = self.get_object()
        titulo = request.data.get("titulo", "")
        mensaje = request.data.get("mensaje", "")
        preview_push = f"[Push] {titulo}: {mensaje}"
        preview_email = f"Asunto: {titulo}\nMensaje: {mensaje}\nFecha: {campania.fecha}\nLugar: {campania.direccion}"
        return Response({"preview_push": preview_push, "preview_email": preview_email})

    @action(detail=True, methods=["get"])
    def reporte(self, request, pk=None):
        campania = self.get_object()
        envios = EnvioCampania.objects.filter(campania=campania)
        total = envios.count()
        entregados = envios.filter(enviado_push=True).count()
        aperturas = envios.exclude(reaccion__isnull=True).count()
        reacciones = envios.values("reaccion").annotate(c=Count("id"))
        return Response({
            "total": total,
            "entregados": entregados,
            "aperturas": aperturas,
            "reacciones": reacciones
        })


# -------------------------------------------------
# ViewSet para la tabla de envíos
class EnvioCampaniaViewSet(viewsets.ModelViewSet):
    queryset = EnvioCampania.objects.all()
    serializer_class = EnvioCampaniaSerializer

    @action(detail=True, methods=['post'], url_path='reaccionar')
    def reaccionar(self, request, pk=None):
        """
        Endpoint POST /api/envios/{pk}/reaccionar/
        Guarda la reacción del usuario para este envío.
        """
        envio = get_object_or_404(
            EnvioCampania,
            id=pk,  # <-- usamos el ID del envío
            destinatario=request.user
        )

        reaccion = request.data.get("reaccion")
        if reaccion not in dict(EnvioCampania.REACCIONES).keys():
            return Response({"error": "Reacción inválida"}, status=400)

        envio.reaccion = reaccion
        envio.save()
        return Response({"status": "ok", "reaccion": envio.reaccion})
    
    





