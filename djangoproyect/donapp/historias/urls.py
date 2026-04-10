# historias/urls.py

from rest_framework.routers import DefaultRouter
from .views import HistoriaViewSet

router = DefaultRouter()
router.register(r'', HistoriaViewSet, basename='historia')

urlpatterns = router.urls