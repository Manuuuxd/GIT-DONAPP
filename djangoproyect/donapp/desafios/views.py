from rest_framework import viewsets
from rest_framework.decorators import action
from rest_framework.response import Response
from django.utils import timezone
from .models import DesafioSemanal, DesafioUsuario, Insignia
from .serializers import DesafioSemanalSerializer, DesafioUsuarioSerializer, InsigniaSerializer


class DesafioSemanalViewSet(viewsets.ModelViewSet):
    queryset = DesafioSemanal.objects.all()
    serializer_class = DesafioSemanalSerializer

    @action(detail=False, methods=['get'])
    def siguiente(self, request):
        """
        Devuelve TODOS los desafíos activos para la semana actual y,
        si aplica, una frase motivacional.
        """
        user = request.user
        today = timezone.now().date()

        # --- LÓGICA MODIFICADA ---
        # 1. Filtramos para obtener todos los desafíos donde la fecha actual
        #    esté entre el inicio y el fin del desafío.
        desafios_activos = DesafioSemanal.objects.filter(
            fecha_inicio__lte=today,
            fecha_fin__gte=today
        )

        # 2. Contar fallos recientes (esta lógica no cambia)
        fallidos = DesafioUsuario.objects.filter(usuario=user, estado="fallido").order_by('-fecha')[:2].count()
        frase = None
        if fallidos >= 2:
            frase = "💪 ¡No te rindas! Cada intento cuenta para salvar vidas."

        # 3. Serializamos la LISTA de desafíos usando many=True
        #    y cambiamos la clave a "desafios" (plural).
        return Response({
            "desafios": DesafioSemanalSerializer(desafios_activos, many=True).data,
            "frase_motivacional": frase
        })


class DesafioUsuarioViewSet(viewsets.ModelViewSet):
    queryset = DesafioUsuario.objects.all()
    serializer_class = DesafioUsuarioSerializer

    def perform_create(self, serializer):
        instancia = serializer.save(usuario=self.request.user)
        self.verificar_insignias(instancia.usuario)

    def verificar_insignias(self, usuario):
        completados = DesafioUsuario.objects.filter(usuario=usuario, estado="completado").count()
        if completados == 3 and not Insignia.objects.filter(usuario=usuario, nombre="Constancia").exists():
            Insignia.objects.create(
                usuario=usuario,
                nombre="Constancia",
                descripcion="Por completar 3 desafíos semanales.",
                icono="insignias/constancia.png"
            )


class InsigniaViewSet(viewsets.ModelViewSet):
    queryset = Insignia.objects.all()
    serializer_class = InsigniaSerializer

