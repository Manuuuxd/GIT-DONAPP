# Archivo: views.py (LA VERSIÓN CORRECTA)

from rest_framework_simplejwt.authentication import JWTAuthentication
from rest_framework.permissions import IsAuthenticated, AllowAny # <-- IMPORTANTE
from rest_framework import viewsets, status
from rest_framework.decorators import action
from rest_framework.response import Response
from django.core.mail import send_mail
from django.conf import settings
from .models import Appointment, DonationCenter
from .serializers import AppointmentSerializer, DonationCenterSerializer
from django.db import transaction

class DonationCenterViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = DonationCenter.objects.all()
    serializer_class = DonationCenterSerializer
    authentication_classes = [JWTAuthentication]

    # --- 🌟 ESTA LÍNEA ARREGLA TU ERROR 401 🌟 ---
    permission_classes = [AllowAny]
    # --- ------------------------------------ ---

class AppointmentViewSet(viewsets.ModelViewSet):
    queryset = Appointment.objects.all()
    serializer_class = AppointmentSerializer
    authentication_classes = [JWTAuthentication]

    def get_permissions(self):
        """
        Permite 'create' (POST) para cualquiera (invitado),
        pero requiere autenticación para todo lo demás (history, cancel, etc).
        """
        if self.action == 'create':
            self.permission_classes = [AllowAny]
        else:
            self.permission_classes = [IsAuthenticated]
        return super().get_permissions()


    def perform_create(self, serializer):
        """Guarda la cita y envía correo al centro de donación."""

        user = None
        user_name = "Invitado"
        if self.request.user and self.request.user.is_authenticated:
            user = self.request.user
            user_name = user.get_full_name() or user.username

        with transaction.atomic():
            appointment = serializer.save(user=user)

        center_email = "jose.manzano@usm.cl"
        subject = "Nueva cita agendada"
        message = (
            f"Se ha agendado una nueva cita.\n\n"
            f"Usuario: {user_name}\n"
            f"RUT: {appointment.rut}\n"
            f"Email: {appointment.email}\n"
            f"Fecha: {appointment.date}\n"
            f"Hora: {appointment.time}\n"
            f"Centro: {appointment.center.name if appointment.center else 'Desconocido'}"
        )

        try:
            send_mail(
                subject,
                message,
                settings.DEFAULT_FROM_EMAIL,
                [center_email],
                fail_silently=False,
            )
        except Exception as e:
            print(f"⚠️ Error enviando correo: {e}")

    @action(detail=False, methods=['get'])
    def history(self, request):
        """Devuelve las citas del usuario logueado"""
        user_appointments = Appointment.objects.filter(user=request.user).order_by('-date', '-time')
        serializer = self.get_serializer(user_appointments, many=True)
        return Response(serializer.data)

    @action(detail=True, methods=['post'])
    def cancel(self, request, pk=None):
        """Cancela una cita con motivo"""
        appointment = self.get_object()
        reason = request.data.get("reason", "")
        if not reason:
            return Response({"error": "Debe especificar un motivo"}, status=status.HTTP_400_BAD_REQUEST)

        appointment.status = "cancelled"
        appointment.cancellation_reason = reason
        appointment.save()
        return Response({"status": "cancelled", "reason": reason}, status=status.HTTP_200_OK)