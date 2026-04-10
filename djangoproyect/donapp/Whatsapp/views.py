import json
from django.http import JsonResponse, HttpResponse
from django.views import View
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator

@method_decorator(csrf_exempt, name='dispatch')
class WhatsappWebhookView(View):

    VERIFY_TOKEN = 'EAAUSdObTWK8BPefXqviwg0VyOCPZAE4wFmYKXTYWcG8yNupwFHiWH5VZA78vmI8j4X8rzTe7qBgotZCO9FZCuyEaWO363e3J6P6P2oE4egYu7EuFLX8q4C0CtOr2zlH0S38ZAoWb6aEf7Yenla7R1RMexT14j03X97NyMvEcKUIA2QF3RSSGvDNpBXkyAe1ErM4tFtZAgyKFka20sPouxJVt0WEF3qBdc4j3U1As6ZCQr6axaEZD'  # para verificar WhatsApp

    def get(self, request):
        # Verificación de webhook
        mode = request.GET.get('hub.mode')
        token = request.GET.get('hub.verify_token')
        challenge = request.GET.get('hub.challenge')

        if mode and token:
            if mode == 'subscribe' and token == self.VERIFY_TOKEN:
                return HttpResponse(challenge, status=200)
            else:
                return HttpResponse('Forbidden', status=403)

        return HttpResponse('OK', status=200)

    def send_whatsapp_message(to_number: str, template_name: str = "hello_world"):
        url = f"https://graph.facebook.com/v22.0/{WHATSAPP_NUMBER_ID}/messages"
        headers = {
            "Authorization": f"Bearer {ACCESS_TOKEN}",
            "Content-Type": "application/json"
        }
        payload = {
            "messaging_product": "whatsapp",
            "to": to_number,
            "type": "template",
            "template": {
                "name": template_name,
                "language": {"code": "en_US"}
            }
        }

        response = requests.post(url, headers=headers, data=json.dumps(payload))
        return response.json()

        def post(self, request):
            data = json.loads(request.body)
            print("Webhook recibido:", json.dumps(data, indent=2))

            # Número del remitente
            from_number = data['entry'][0]['changes'][0]['value']['messages'][0]['from']
            text = data['entry'][0]['changes'][0]['value']['messages'][0]['text']['body']

            # Procesa con tu bot
            response_text = my_bot.process_message(text)

            # Envía respuesta a WhatsApp
            send_whatsapp_message(from_number, template_name="hello_world")  # o crear un template dinámico

            return JsonResponse({'status': 'received'}, status=200)