from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status, generics
from .models import Achievement, UserItem, Items
from .serializers import AchievementSerializer, UserItemSerializer, ItemsSerializer
from .utils import check_and_unlock_achievement

class UserAchievementsView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        try:
            achievements = Achievement.objects.all()
            serializer = AchievementSerializer(achievements, many=True, context={'request': request})
            return Response(serializer.data)
        except Exception as e:
            print('Error interno en logros API:', repr(e))  # imprimir excepción en consola
            return Response(
                {'error': 'Error interno del servidor', 'detalle': str(e)},
                status=status.HTTP_500_INTERNAL_SERVER_ERROR
            )
        
class OtorgarLogroAPI(APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        print ('Datos recibidos en OtorgarLogroAPI:', request.data)  # Depuración
        slug_key = request.data.get('slug_key')
        print ('slug_key recibido:', slug_key)  # Depuración
        if not slug_key:
            return Response({'error': 'slug_key es requerido'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            print(f"Desbloqueando logro '{slug_key}' para el usuario {request.user.username}")
            desbloqueado = check_and_unlock_achievement(request.user, slug_key)
            print(f"Resultado de desbloqueo: {desbloqueado}")
            return Response(desbloqueado, status=status.HTTP_200_OK)     
        except Exception as e:
            return Response({'error': 'Error interno del servidor', 'detalle': str(e)},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
class OtorgarItemAPI (APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        print ('Datos recibidos en OtorgarItemAPI:', request.data)  # Depuración
        slug = request.data.get('slug')
        cantidad = request.data.get('cantidad', 1)
        print ('slug recibido:', slug)  # Depuración
        if not slug:
            return Response({'error': 'slug es requerido'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            from .utils import otorgar_item
            print (request.user.id)
            user_item = otorgar_item(request.user, slug, cantidad)
            return Response({'status': 'item_otorgado', 'item_slug': slug, 'cantidad': user_item.cantidad},
                            status=status.HTTP_200_OK)     
        except Exception as e:
            return Response({'error': 'Error interno del servidor', 'detalle': str(e)},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        
class CanjarItemAPI (APIView):
    permission_classes = [IsAuthenticated]
    def post(self, request):
        print ('Datos recibidos en CanjearItemAPI:', request.data)  # Depuración
        slug = request.data.get('slug')
        cantidad = request.data.get('cantidad', 1)
        print ('slug recibido:', slug)  # Depuración
        if not slug:
            return Response({'error': 'slug es requerido'}, status=status.HTTP_400_BAD_REQUEST)
        try:
            from .utils import canjear_item
            user_item = canjear_item(request.user, slug, cantidad)
            return Response({'status': 'item_canjeado', 'item_slug': slug, 'cantidad': user_item.cantidad},
                            status=status.HTTP_200_OK)     
        except Exception as e:
            return Response({'error': 'Error interno del servidor', 'detalle': str(e)},
                            status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        

class UserItemsList(generics.ListAPIView):
    serializer_class = UserItemSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return UserItem.objects.filter(user=self.request.user)

class ItemsList(generics.ListAPIView):
    serializer_class = ItemsSerializer
    permission_classes = [IsAuthenticated]

    def get_queryset(self):
        return Items.objects.all()