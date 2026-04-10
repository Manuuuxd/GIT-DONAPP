# trivia/urls.py
from django.urls import path
from .views import QuestionListAPIView, TriviaSessionCreateAPIView, TriviaSessionListAPIView, TriviaAnswerSessionView, ia_mock

urlpatterns = [
    path('questions/', QuestionListAPIView.as_view(), name='questions-list'),
    path('sessions/', TriviaSessionListAPIView.as_view(), name='sessions-list'),
    path('sessions/create/', TriviaSessionCreateAPIView.as_view(), name='sessions-create'),
    path('sessions/answers/', TriviaAnswerSessionView.as_view(), name='trivia-answers'),
    path('ia', ia_mock),
]