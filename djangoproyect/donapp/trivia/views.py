import json
import requests
from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework_simplejwt.authentication import JWTAuthentication

from .models import Question, TriviaSession
from .serializers import QuestionSerializer, TriviaSessionSerializer, TriviaSessionCreateSerializer
from usuarios.utils import otorgar_xp

class QuestionListAPIView(generics.ListAPIView):
    queryset = Question.objects.all()
    serializer_class = QuestionSerializer
    permission_classes = [permissions.AllowAny]

class TriviaSessionCreateAPIView(generics.CreateAPIView):
    serializer_class = TriviaSessionCreateSerializer
    permission_classes = [permissions.IsAuthenticated]

    def perform_create(self, serializer):
        serializer.save(user=self.request.user)

class TriviaSessionListAPIView(generics.ListAPIView):
    serializer_class = TriviaSessionSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return TriviaSession.objects.filter(user=self.request.user).order_by('-created_at')

NIVEL_MAP = {
    range(1, 4): "Inicial",
    range(4, 7): "Avanzado",
    range(7, 11): "Experto",
}

def obtener_nivel_usuario_etiqueta(nivel_num):
    for rango, etiqueta in NIVEL_MAP.items():
        if nivel_num in rango:
            return etiqueta
    return "Inicial"

class TriviaAnswerSessionView(APIView):
    authentication_classes = [JWTAuthentication]
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            data = request.data

            if not {'record', 'statistics', 'n'}.issubset(data):
                return Response({'error': 'Faltan campos requeridos'}, status=status.HTTP_400_BAD_REQUEST)

            api_response = requests.post(
                "http://localhost:8001/ia",
                headers={"Content-Type": "application/json"},
                json=data
            )

            if api_response.status_code != 200:
                return Response({'error': 'Error al comunicarse con la API interna'}, status=500)

            respuesta_ia = api_response.json()
            preguntas_por_area = respuesta_ia.get("preguntas_por_area", {})
            nuevas_estadisticas = respuesta_ia.get("nuevas_estadisticas", {})

            perfil = getattr(request.user, 'profile', None)
            if not perfil:
                return Response({'error': 'Usuario sin perfil asociado'}, status=400)

            xp_total = 0
            record = data.get("record", [])
            dificultad = data.get("dificultad", "Inicial")

            for entrada in record:
                correcta = entrada.get("correcta", False)
                xp_entrada = otorgar_xp(perfil, dificultad, correcta, 20, [])
                xp_total += xp_entrada

            perfil.save()
            nivel_usuario = perfil.nivel
            nivel_etiqueta = obtener_nivel_usuario_etiqueta(nivel_usuario)

            preguntas_totales = []
            usadas_areas = set()

            for area, cantidad in preguntas_por_area.items():
                usadas_areas.add(area)
                preguntas = Question.objects.filter(area=area, level=nivel_etiqueta).order_by('?')[:cantidad]
                preguntas_totales.extend(preguntas)

                faltan = cantidad - len(preguntas)
                if faltan > 0:
                    otras_preguntas = (
                        Question.objects.exclude(area__in=usadas_areas)
                        .filter(level=nivel_etiqueta)
                        .order_by('?')[:faltan]
                    )
                    preguntas_totales.extend(otras_preguntas)

            preguntas_serializadas = []
            print(area)
            for q in preguntas_totales:
                respuestas = q.answers.all()
                respuestas_serializadas = [
                    {
                        "id": a.id,
                        "label": a.label,
                        "text": a.text,
                        "is_correct": a.is_correct,
                    }
                    for a in respuestas
                ]

                preguntas_serializadas.append({
                    "id": q.id,
                    "text": q.text,
                    "explanation": q.explanation,
                    "area": q.area,
                    "level": q.level,
                    "answers": respuestas_serializadas,
                })
            print("dificultad:", dificultad)
            print("Preguntas Realizadas : \n", preguntas_serializadas)
            return Response({
                "preguntas": preguntas_serializadas,
                "nuevas_estadisticas": nuevas_estadisticas,
                "xp_ganado": xp_total,
                "nuevo_nivel": perfil.nivel
            })

        except json.JSONDecodeError:
            return Response({'error': 'JSON inválido'}, status=400)
        except Exception as e:
            return Response({'error': str(e)}, status=500)

@csrf_exempt
def ia_mock(request):
    if request.method == 'POST':
        return JsonResponse({
            "new_statistics": {
                "Requisitos para donar": 2,
                "Compatibilidad sanguínea": 2,
                "Proceso de donación": 4,
                "Frecuencia permitida": 2,
                "Mitos y verdades": 4
            },
            "questions_per_area": {
                "Requisitos para donar": 2,
                "Compatibilidad sanguínea": 1,
                "Proceso de donación": 0,
                "Frecuencia permitida": 2,
                "Mitos y verdades": 0
            }
        })
