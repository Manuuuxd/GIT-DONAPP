# survey/views.py
from rest_framework import viewsets
from .models import Survey, SurveyResponse
from .serializers import SurveySerializer, SurveyResponseSerializer
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.permissions import AllowAny



class SurveyViewSet(viewsets.ReadOnlyModelViewSet):
    queryset = Survey.objects.all().order_by("id")
    serializer_class = SurveySerializer
    permission_classes = [AllowAny]

    # Custom PATCH endpoints to match your ApiService
    @action(detail=True, methods=['patch'])
    def segment(self, request, pk=None):
        survey = self.get_object()
        segment_data = request.data  # your frontend sends a Map<String,dynamic>
        # Example: store segment info in a JSONField (you can add it to your model)
        survey.segmentacion = segment_data
        survey.save()
        return Response({"status": "ok"})

    @action(detail=True, methods=['patch'])
    def channels(self, request, pk=None):
        survey = self.get_object()
        channels = request.data.get("channels", [])
        # store channels in a JSONField or ArrayField
        survey.canales = channels
        survey.save()
        return Response({"status": "ok"})

class SurveyResponseViewSet(viewsets.ModelViewSet):
    queryset = SurveyResponse.objects.all()
    serializer_class = SurveyResponseSerializer

    def perform_create(self, serializer):
        survey = serializer.validated_data["survey"]
        data = serializer.validated_data["data"]
        user_id = data.get("user")

        if user_id is None:
            raise ValidationError("Missing user ID in data.")

        # Check if this user already has a response for this survey
        already_responded = SurveyResponse.objects.filter(
            survey=survey,
            data__user=user_id  # JSONField lookup
        ).exists()

        if already_responded:
            raise ValidationError("User has already responded to this survey.")

        # Save normally if not responded
        serializer.save()


    @action(detail=False, methods=["get"])
    def has_responded(self, request):
        survey_id = request.query_params.get("survey_id")
        user_id = request.query_params.get("user_id")

        if not survey_id or not user_id:
            return Response({"error": "survey_id and user_id are required"}, status=400)

        responded = SurveyResponse.objects.filter(
            survey_id=survey_id,
            data__user=int(user_id)  # lookup inside JSON
        ).exists()

        return Response({"has_responded": responded})

from django.http import JsonResponse
from django.views.decorators.csrf import csrf_exempt
@csrf_exempt
def test_connection(request):
    print("✅ Flutter hit the backend!")  # <-- check your terminal
    return JsonResponse({"status": "ok"})
