from django.urls import path
from .views import ChatAssistantWithModelView,ChatBotWithModelView, ChatFeedbackView

urlpatterns = [
    path("chatassistant/", ChatAssistantWithModelView.as_view(), name="chat"),
    path("chatbot/", ChatBotWithModelView.as_view(), name="chat"),
    path("feedback/", ChatFeedbackView.as_view(), name="chat-feedback"),
]
