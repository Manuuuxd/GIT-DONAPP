from rest_framework import serializers
from .models import Conversation, Message

class MessageSerializer(serializers.ModelSerializer):
    class Meta:
        model = Message
        fields = ['id', 'content', 'is_user', 'timestamp']

class ConversationSerializer(serializers.ModelSerializer):
    messages = MessageSerializer(many=True, read_only=True)
    
    class Meta:
        model = Conversation
        fields = ['id', 'title', 'created_at', 'messages']

from .models import ChatFeedback

class ChatFeedbackSerializer(serializers.ModelSerializer):
    class Meta:
        model = ChatFeedback
        fields = ["id", "user", "comment", "created_at"]
        read_only_fields = ["id", "user", "created_at"]