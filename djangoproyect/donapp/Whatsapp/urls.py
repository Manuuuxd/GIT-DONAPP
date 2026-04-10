from django.urls import path
from . import views

urlpatterns = [
    path('webhook/', views.WhatsappWebhookView.as_view(), name='whatsapp_webhook'),
]