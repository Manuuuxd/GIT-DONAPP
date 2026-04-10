from rest_framework.routers import DefaultRouter
from .views import DesafioSemanalViewSet, DesafioUsuarioViewSet, InsigniaViewSet

router = DefaultRouter()

# --- ORDEN CORREGIDO ---

# 1. Registrar las rutas más específicas PRIMERO.
# Esto asegura que Django las revise antes de la ruta general.
router.register(r'usuario', DesafioUsuarioViewSet, basename='desafios-usuario')
router.register(r'insignias', InsigniaViewSet, basename='insignias')

# 2. Registrar la ruta raíz (la más general) AL FINAL.
router.register(r'', DesafioSemanalViewSet, basename='desafios')


urlpatterns = router.urls
