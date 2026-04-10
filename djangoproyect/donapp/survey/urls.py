from django.urls import path, include
from rest_framework.routers import DefaultRouter
from .views import SurveyViewSet, SurveyResponseViewSet
from .views import test_connection
router = DefaultRouter()
router.register(r"survey", SurveyViewSet, basename="survey")
router.register(r"responses", SurveyResponseViewSet, basename="response")
urlpatterns = [
    path('', include(router.urls)),
    path("test/", test_connection),
]
