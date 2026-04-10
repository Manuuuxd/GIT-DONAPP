# trivia/models.py
from django.db import models
from django.contrib.auth.models import User

class Question(models.Model):
    text = models.CharField(max_length=500)
    explanation = models.TextField(blank=True, null=True)
    level = models.CharField(max_length=50)  # Ej: "Inicial"
    area = models.CharField(max_length=100)  # Ej: "Requisitos para donar"

    def __str__(self):
        return f"{self.text} ({self.level} - {self.area})"

class Answer(models.Model):
    question = models.ForeignKey(Question, on_delete=models.CASCADE, related_name='answers')
    label = models.CharField(max_length=1)
    text = models.CharField(max_length=255)
    is_correct = models.BooleanField(default=False)

    def __str__(self):
        return f"{self.label}. {self.text}"

class TriviaSession(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name='trivia_sessions')
    score = models.FloatField()
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"Session {self.id} - {self.user.username}"

class UserAnswer(models.Model):
    session = models.ForeignKey(TriviaSession, on_delete=models.CASCADE, related_name="answers")
    question = models.ForeignKey(Question, on_delete=models.CASCADE)
    selected_answer = models.ForeignKey(Answer, on_delete=models.SET_NULL, null=True)
    was_correct = models.BooleanField()

    def __str__(self):
        return f"Answer to '{self.question.text}' was {'correct' if self.was_correct else 'wrong'}"