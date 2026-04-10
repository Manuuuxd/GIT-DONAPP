# views.py
import json, logging
from django.http import JsonResponse
from django.utils.decorators import method_decorator
from django.views.decorators.csrf import csrf_exempt
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from .services.router import route_question
from .services.textutils import is_valid_question
from .services.config import ChatConfig

logger = logging.getLogger(__name__)

# Config A y B (podrías cargarlas de env)
CFG_A = ChatConfig(
    name="sistema_A",
    language="es",
    endpoint_id="RUNPOD_ENDPOINT_ID_A",
    qdrant_collection="kb_a",
    qdrant_filters={"language": "es", "tenant": "A"},
    faq_tenant="A",
    tau_direct=0.75,
    tau_rag=0.55,
)

CFG_B = ChatConfig(
    name="sistema_B",
    language="es",
    endpoint_id="RUNPOD_ENDPOINT_ID_B",
    qdrant_collection="kb_b",
    qdrant_filters={"language": "es", "tenant": "B"},  # antes tenias "lang"
    faq_tenant="B",
    tau_direct=0.60,   # baja umbrales en dev pa validar
    tau_rag=0.45,
)


class _BaseChatView(APIView):
    permission_classes = [IsAuthenticated]
    CFG: ChatConfig = None

    def post(self, request):
        try:
            # ✅ Usa el parser de DRF primero, y si no hay data cae al body
            try:
                body = request.data if isinstance(request.data, dict) else {}
                print(body)
                if not body:
                    body = json.loads((request.body or b"{}").decode("utf-8"))
            except (json.JSONDecodeError, UnicodeDecodeError):
                return JsonResponse({"error": "JSON inválido"}, status=400)

            user_message = (body.get("message") or "").strip()
            if not user_message:
                return JsonResponse({"error": "El mensaje no puede estar vacío"}, status=400)

            if not is_valid_question(user_message):
                return JsonResponse({
                    "user_message": user_message,
                    "actions": [{"action": "send_message", "data": "No puedo procesar ese contenido"}],
                    "route": "guardrail"
                }, status=200)

            result = route_question(
                question=user_message,
                user_id=str(request.user.id),
                cfg=self.CFG
            )

            actions = [{"action": "send_message", "data": result["answer"]}]
            if result.get("action"):
                actions.append({"action": "assistant", "data": result["action"]})
            print(result)
            return JsonResponse({
                "user_message": user_message,
                "actions": actions,
                "route": result["route"],
                "scores": result.get("scores"),
                "sources": result.get("sources"),
                "tenant": self.CFG.name,
            }, status=200)

        except Exception as e:
            logger.exception(f"Error en chat {self.CFG.name}")
            return JsonResponse({"error": str(e)}, status=500)

@method_decorator(csrf_exempt, name='dispatch')
class ChatBotWithModelView(_BaseChatView):
    CFG = CFG_A

@method_decorator(csrf_exempt, name='dispatch')
class ChatAssistantWithModelView(_BaseChatView):
    CFG = CFG_B
    
    
class ChatFeedbackView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        try:
            from django.conf import settings
            from django.core.mail import send_mail
            from .models import ChatFeedback

            body = json.loads(request.body or "{}")
            comment = (body.get("comment") or "").strip()
            tenant = (body.get("tenant") or "default").upper()  # "A" | "B" | "default"
            conversation_id = body.get("conversation_id")  # opcional
            route = body.get("route")  # opcional: "faq_exact" | "semantic_direct" | "rag" | "llm"

            if not comment:
                return JsonResponse({"error": "El comentario no puede estar vacío"}, status=400)

            fb = ChatFeedback.objects.create(user=request.user, comment=comment)

            subject = f"Nuevo Feedback del Chat ({tenant})"
            message = (
                f"Sistema: {tenant}\n"
                f"Usuario: {request.user.username} ({request.user.email})\n"
                f"Conversación: {conversation_id or 'N/A'}\n"
                f"Ruta: {route or 'N/A'}\n"
                f"Comentario: {fb.comment}\n"
                f"Fecha: {fb.created_at:%Y-%m-%d %H:%M:%S}\n"
            )

            recipients_map = {
                "A": ["soporteA@tuempresa.com"],
                "B": ["soporteB@tuempresa.com"],
                "DEFAULT": ["Gabriel.Leyton@usm.cl"]
            }
            recipients = recipients_map.get(tenant, recipients_map["DEFAULT"])

            send_mail(subject, message, settings.EMAIL_HOST_USER, recipients, fail_silently=False)

            return JsonResponse({"success": True, "message": "Feedback recibido", "id": fb.id}, status=200)

        except Exception as e:
            return JsonResponse({"error": str(e)}, status=500)
