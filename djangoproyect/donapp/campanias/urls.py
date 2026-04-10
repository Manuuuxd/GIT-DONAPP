from rest_framework.routers import DefaultRouter
from .views import CampaniaViewSet, EnvioCampaniaViewSet

router = DefaultRouter()
router.register(r'campanias', CampaniaViewSet, basename='campanias')
router.register(r'envios', EnvioCampaniaViewSet, basename='envios')

urlpatterns = list(router.urls)
