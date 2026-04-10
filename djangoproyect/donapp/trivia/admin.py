from django.contrib import admin
from .models import Question, Answer, TriviaSession, UserAnswer

admin.site.register(Question)
admin.site.register(Answer)
admin.site.register(TriviaSession)
admin.site.register(UserAnswer)