# trivia/serializers.py
from rest_framework import serializers
from django.contrib.auth.models import User
from .models import Question, Answer, TriviaSession, UserAnswer

class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'username', 'email']

class AnswerSerializer(serializers.ModelSerializer):
    class Meta:
        model = Answer
        fields = ['id', 'label', 'text', 'is_correct']

class QuestionSerializer(serializers.ModelSerializer):
    answers = AnswerSerializer(many=True, read_only=True)

    class Meta:
        model = Question
        fields = ['id', 'text', 'explanation', 'level', 'area', 'answers']

class UserAnswerSerializer(serializers.ModelSerializer):
    question = QuestionSerializer(read_only=True)
    selected_answer = AnswerSerializer(read_only=True)

    class Meta:
        model = UserAnswer
        fields = ['id', 'question', 'selected_answer', 'was_correct']

class TriviaSessionSerializer(serializers.ModelSerializer):
    answers = UserAnswerSerializer(many=True, read_only=True)
    user = UserSerializer(read_only=True)

    class Meta:
        model = TriviaSession
        fields = ['id', 'user', 'score', 'created_at', 'answers']

# Para crear sesión y respuestas juntos
class UserAnswerCreateSerializer(serializers.ModelSerializer):
    class Meta:
        model = UserAnswer
        fields = ['question', 'selected_answer', 'was_correct']

class TriviaSessionCreateSerializer(serializers.ModelSerializer):
    answers = UserAnswerCreateSerializer(many=True)

    class Meta:
        model = TriviaSession
        fields = ['score', 'answers']

    def create(self, validated_data):
        answers_data = validated_data.pop('answers')
        user = self.context['request'].user
        session = TriviaSession.objects.create(user=user, **validated_data)
        for answer_data in answers_data:
            UserAnswer.objects.create(session=session, **answer_data)
        return session
