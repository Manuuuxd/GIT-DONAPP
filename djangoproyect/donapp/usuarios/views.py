from rest_framework import generics, permissions, status
from rest_framework.views import APIView
from rest_framework.response import Response
from django.contrib.auth.models import User
from rest_framework.authtoken.models import Token
from .email_utils import enviar_recordatorio_con_imagen
from django.http import JsonResponse
from rest_framework_simplejwt.views import TokenObtainPairView
from django.contrib.auth.signals import user_logged_in
from django.utils.dateparse import parse_date
from rest_framework.permissions import IsAuthenticated
from django.views.decorators.csrf import csrf_exempt
from django.utils.decorators import method_decorator
from django.db import transaction

from django.core.mail import send_mail
from django.utils import timezone
from django.conf import settings
from django.shortcuts import get_object_or_404

import secrets, datetime
from rest_framework_simplejwt.tokens import RefreshToken

from .models import UserProfile, UserAvatar
from .serializers import UserSerializer, UserRegisterSerializer, UserProfileSerializer, UserProfileUpdateSerializer, UserProfileChoicesSerializer, CustomTokenObtainPairSerializer, UserAvatarSerializer
from logros.utils import check_and_unlock_achievement

# Modelo temporal de tokens de recuperación
from .models import PasswordResetToken

# Registrar nuevo usuario
class RegisterUserAPI(generics.CreateAPIView):
    serializer_class = UserRegisterSerializer
    permission_classes = [permissions.AllowAny]

    def perform_create(self, serializer):
        user = serializer.save()
        try:
            check_and_unlock_achievement(user, 'primer_acceso')  # Desbloquear logro de registro
        except Exception as e:
            # Opcional: loguear el error
            import logging
            logger = logging.getLogger(__name__)
            logger.error(f"Error desbloqueando logro para {user.username}: {e}")

class UserDetailAPI(generics.RetrieveAPIView):
    """
    Vista para obtener los detalles del usuario autenticado.
    """
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user

# Actualizar perfil
class UserProfileUpdateAPI(generics.RetrieveUpdateAPIView):
    serializer_class = UserProfileSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        return self.request.user.profile

# Obtener nivel del usuario
class UserNivelAPI(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def get(self, request):
        return Response(request.user.profile.nivel)

class CustomTokenObtainPairView(TokenObtainPairView):
    serializer_class = CustomTokenObtainPairSerializer

    def post(self, request, *args, **kwargs):
        response = super().post(request, *args, **kwargs)

        if response.status_code == 200:
            serializer = self.get_serializer(data=request.data)
            serializer.is_valid(raise_exception=True)
            user = serializer.user

        return response

@method_decorator(csrf_exempt, name='dispatch')
class ActualizarOnesignalView(APIView):
    """
    Vista para actualizar el onesignal_player_id del usuario autenticado.
    """
    permission_classes = [IsAuthenticated]

    def post(self, request, *args, **kwargs):
        # Se asegura de que el perfil exista
        profile, created = UserProfile.objects.get_or_create(user=request.user)

        serializer = UserProfileUpdateSerializer(profile, data=request.data, partial=True)
        
        if serializer.is_valid():
            serializer.save()
            return Response({"status": "ok", "onesignal_player_id": profile.onesignal_player_id}, status=status.HTTP_200_OK)
        
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

def enviar_recordatorio_test(request):
    user = User.objects.first()
    enviar_recordatorio_con_imagen(user.email, user.first_name or user.username)
    return JsonResponse({'status': 'correo enviado'})

class UsuarioListView(generics.ListAPIView):
    serializer_class = UserProfileSerializer    

    def get_queryset(self):
        queryset = UserProfile.objects.all()
        
        region = self.request.query_params.get('region')
        provincia = self.request.query_params.get('provincia')
        comuna = self.request.query_params.get('comuna')
        apto_para_donar = self.request.query_params.get('apto_para_donar')
        sexo = self.request.query_params.get('sexo')
        tipo_sangre = self.request.query_params.get('tipo_sangre')
        fecha_desde = self.request.query_params.get('fecha_desde')
        fecha_hasta = self.request.query_params.get('fecha_hasta')

        if region:
            queryset = queryset.filter(region=region)
        if provincia:
            queryset = queryset.filter(provincia=provincia)
        if comuna:
            queryset = queryset.filter(comuna=comuna)
        if apto_para_donar is not None:
            if apto_para_donar.lower() == 'true':
                queryset = queryset.filter(apto_para_donar=True)
            elif apto_para_donar.lower() == 'false':
                queryset = queryset.filter(apto_para_donar=False)
        if sexo:
            queryset = queryset.filter(sexo=sexo)
        if tipo_sangre:
            queryset = queryset.filter(tipo_sangre=tipo_sangre)
        if fecha_desde and fecha_hasta:
            f_desde = parse_date(fecha_desde)
            f_hasta = parse_date(fecha_hasta)
            if f_desde and f_hasta:
                queryset = queryset.filter(fecha_ultima_donacion__range=(f_desde, f_hasta))

        return queryset
        


from rest_framework.permissions import AllowAny

class RequestPasswordResetView(APIView):
    permission_classes = [AllowAny]
    """
    Paso 1
    """
    def post(self, request):
        email = request.data.get("email")
        if not email:
            return Response({"error": "Email requerido"}, status=status.HTTP_400_BAD_REQUEST)

        try:
            user = User.objects.get(email=email)
        except User.DoesNotExist:
            return Response({"message": "Si el correo existe, se envió un enlace"}, status=status.HTTP_200_OK)

        token = secrets.token_urlsafe(32)
        expires_at = timezone.now() + datetime.timedelta(hours=24)

        PasswordResetToken.objects.create(user=user, token=token, expires_at=expires_at)

        send_mail(
            subject="Recuperación de cuenta - Donapp",
            message=f"Hola {user.username},\n\nTu código de recuperación es:\n\n{token}\n\n"
                    "Usa este código en la app para restablecer tu contraseña (válido 24h).",
            from_email=settings.DEFAULT_FROM_EMAIL,
            recipient_list=[email],
        )

        return Response({"message": "Se envió un enlace de recuperación al correo"}, status=status.HTTP_200_OK)


class ResetPasswordView(APIView):
    permission_classes = [AllowAny]

    """
    Paso 2: Usuario ingresa el token y la nueva contraseña
    """
    def post(self, request, token):
        try:
            new_password = request.data.get("new_password")
            if not new_password:
                return Response(
                    {"error": "Nueva contraseña requerida"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            # (Opcional) validación básica de seguridad
            if len(new_password) < 8:
                return Response(
                    {"error": "La contraseña debe tener al menos 8 caracteres"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            reset_token = get_object_or_404(PasswordResetToken, token=token)

            # validar expiración
            if reset_token.expires_at < timezone.now():
                reset_token.delete()
                return Response(
                    {"error": "El enlace expiró"},
                    status=status.HTTP_400_BAD_REQUEST
                )

            user = reset_token.user
            user.set_password(new_password)
            user.save()

            reset_token.delete()  # borrar token usado

            # ✅ Generar JWT como en login
            refresh = RefreshToken.for_user(user)
            return Response(
                {
                    "message": "Contraseña restablecida con éxito",
                    "access": str(refresh.access_token),
                    "refresh": str(refresh),
                },
                status=status.HTTP_200_OK
            )

        except Exception as e:
            # Captura de cualquier error inesperado
            import traceback
            traceback.print_exc()
            return Response(
                {"error": f"Error interno: {str(e)}"},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )

class UserDetailAPI(generics.RetrieveAPIView):
    """
    Vista para obtener los detalles del usuario autenticado.
    """
    serializer_class = UserSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        return self.request.user


class UserProfileUpdateAPI(generics.UpdateAPIView):
    """
    Vista para actualizar el perfil del usuario autenticado.
    """
    serializer_class = UserProfileUpdateSerializer
    permission_classes = [IsAuthenticated]

    def get_object(self):
        try:
            return self.request.user.profile
        except UserProfile.DoesNotExist:
            raise status.HTTP_404_NOT_FOUND("El perfil de usuario no existe.")

    def update(self, request, *args, **kwargs):
        with transaction.atomic():
            profile_serializer = self.get_serializer(
                self.get_object(),
                data=request.data,
                partial=True
            )
            profile_serializer.is_valid(raise_exception=True)
            profile_serializer.save()

            # Opcionalmente, puedes actualizar el nombre del usuario si está en el payload
            if 'nombre' in request.data:
                user = self.request.user
                user.first_name = request.data['nombre']
                user.save()

        return Response(profile_serializer.data, status=status.HTTP_200_OK)

class UserProfileChoicesAPI(APIView):
    """
    Vista para obtener las opciones de los campos de UserProfile.
    """
    def get(self, request, *args, **kwargs):
        sexo_choices = dict(UserProfile.SEXO_CHOICES)
        tipo_sangre_choices = dict(UserProfile.TIPO_SANGRE_CHOICES)
        
        data = {
            'sexo': sexo_choices,
            'tipo_sangre': tipo_sangre_choices,
        }
        
        serializer = UserProfileChoicesSerializer(data)
        return Response(serializer.data)



class UserExperienciaAPI(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        profile = request.user.profile
        profile.actualizar_nivel()
        profile.save()
        return Response({
            "xp": profile.xp,
            "nivel": profile.nivel,
        })

    def post(self, request):
        profile = request.user.profile
        gained_xp = int(request.data.get("xp", 0))

        # Decide: overwrite or accumulate?
        profile.xp += gained_xp   # <-- accumulate XP

        profile.actualizar_nivel()
        profile.save()

        return Response({
            "xp": profile.xp,
            "nivel": profile.nivel,
        })
    def _xp_proximo_nivel(self, profile):
        # tabla de requisitos
        niveles = [
            (1, 0),
            (2, 50),
            (3, 120),
            (4, 200),
            (5, 300),
            (6, 450),
            (7, 600),
            (8, 800),
            (9, 1050),
            (10, 1400),
        ]
        actual = profile.nivel
        for n, req_xp in niveles:
            if n == actual + 1:
                return req_xp
        return None  # ya está en el máximo nivel

    def _progreso(self, profile):
        niveles = {
            1: 0,
            2: 50,
            3: 120,
            4: 200,
            5: 300,
            6: 450,
            7: 600,
            8: 800,
            9: 1050,
            10: 1400,
        }
        xp_actual = profile.xp
        xp_nivel = niveles.get(profile.nivel, 0)
        xp_next = niveles.get(profile.nivel + 1)

        if not xp_next:  # ya está en el último nivel
            return 100

        return round(((xp_actual - xp_nivel) / (xp_next - xp_nivel)) * 100, 2)
    
from .models import FriendRequest, UserProfile
from .serializers import FriendRequestSerializer

# Enviar solicitud de amistad
class SendFriendRequestAPI(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request):
        sender = request.user
        username = request.data.get('username')
        if not username:
            return Response({'detail': 'Debe ingresar un nombre de usuario.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            receiver = User.objects.get(username=username)
        except User.DoesNotExist:
            return Response({'detail': 'El usuario no existe.'}, status=status.HTTP_404_NOT_FOUND)

        # ✅ No permitir enviarse solicitud a sí mismo
        if receiver == sender:
            return Response({'detail': 'No puedes enviarte una solicitud a ti mismo.'}, status=status.HTTP_400_BAD_REQUEST)

        # ✅ No permitir si ya son amigos
        if receiver.profile in sender.profile.amigos.all():
            return Response({'detail': 'Ya son amigos.'}, status=status.HTTP_400_BAD_REQUEST)

        # ✅ No permitir si ya existe una solicitud pendiente
        if FriendRequest.objects.filter(sender=sender, receiver=receiver, accepted=False).exists():
            return Response({'detail': 'Ya has enviado una solicitud pendiente a este usuario.'}, status=status.HTTP_400_BAD_REQUEST)

        # ✅ No permitir si el otro usuario ya te envió una solicitud pendiente
        if FriendRequest.objects.filter(sender=receiver, receiver=sender, accepted=False).exists():
            return Response({'detail': 'Este usuario ya te envió una solicitud pendiente.'}, status=status.HTTP_400_BAD_REQUEST)

        # ✅ Crear solicitud
        FriendRequest.objects.create(sender=sender, receiver=receiver)
        return Response({'detail': 'Solicitud enviada correctamente.'}, status=status.HTTP_200_OK)



# Listar solicitudes recibidas pendientes
class PendingFriendRequestsAPI(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        solicitudes = FriendRequest.objects.filter(receiver=request.user, accepted=False)
        serializer = FriendRequestSerializer(solicitudes, many=True)
        return Response(serializer.data)


# Aceptar o rechazar solicitud
class RespondFriendRequestAPI(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        action = request.data.get('action')  # "accept" o "reject"
        try:
            fr = FriendRequest.objects.get(id=pk, receiver=request.user)
        except FriendRequest.DoesNotExist:
            return Response({'error': 'Solicitud no encontrada.'}, status=404)

        if action == 'accept':
            fr.accepted = True
            fr.save()
            # vincula en amigos
            sender_profile = fr.sender.profile
            receiver_profile = fr.receiver.profile
            sender_profile.amigos.add(receiver_profile)
            receiver_profile.amigos.add(sender_profile)
            return Response({'message': 'Solicitud aceptada.'}, status=200)
        elif action == 'reject':
            fr.delete()
            return Response({'message': 'Solicitud rechazada.'}, status=200)
        else:
            return Response({'error': 'Acción inválida.'}, status=400)


# Listar amigos del usuario
class FriendsListAPI(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        amigos = request.user.profile.amigos.all()
        data = [{'username': a.user.username, 'nivel': a.nivel, 'xp': a.xp} for a in amigos]
        return Response(data)


class UserAvatarView(generics.RetrieveUpdateAPIView):
    serializer_class = UserAvatarSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_object(self):
        obj, _ = UserAvatar.objects.get_or_create(user=self.request.user)
        return obj