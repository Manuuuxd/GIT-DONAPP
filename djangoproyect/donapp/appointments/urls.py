from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import AppointmentViewSet, DonationCenterViewSet

router = DefaultRouter()
router.register(r'appointments', AppointmentViewSet, basename='appointment')
router.register(r'centers', DonationCenterViewSet, basename='center')

urlpatterns = [
    path('', include(router.urls)),
]
