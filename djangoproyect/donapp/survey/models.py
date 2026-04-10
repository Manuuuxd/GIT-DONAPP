from django.db import models
from django.utils import timezone
from django.contrib.postgres.fields import ArrayField

class Survey(models.Model):
    title = models.CharField(max_length=255)

    description = models.TextField(blank=True)

    questions = ArrayField(models.CharField(max_length=500))

    created_at = models.DateTimeField(auto_now_add=True)

    segmentacion = models.JSONField(default=dict, blank=True)

    canales = ArrayField(models.CharField(max_length=100), default=list, blank=True)

    def __str__(self):
        return self.title

class SurveyResponse(models.Model):
    survey = models.ForeignKey(Survey, on_delete=models.CASCADE)
    data = models.JSONField()  # Stores answers as JSON
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Response to {self.survey.title} at {self.created_at}"