# usuarios/email_utils.py
from django.core.mail import EmailMultiAlternatives
from django.template.loader import render_to_string
from django.conf import settings
from email.mime.image import MIMEImage
import os

def enviar_recordatorio_con_imagen(user_email, user_name):
    subject = '🩸 ¡Es momento de volver a donar!'
    from_email = settings.DEFAULT_FROM_EMAIL
    to = [user_email]

    html_content = render_to_string('emails/recordatorio.html', {'user_name': user_name})
    msg = EmailMultiAlternatives(subject, '', from_email, to)
    msg.attach_alternative(html_content, "text/html")

    # Ruta absoluta a la imagen
    image_path = os.path.join(settings.BASE_DIR, 'static', 'img', 'donacion.png')

    with open(image_path, 'rb') as img:
        image = MIMEImage(img.read())
        image.add_header('Content-ID', '<corazon>')  # Importante para embebido en HTML
        msg.attach(image)

    msg.send()
