from django.db import models
from django.contrib.auth.models import User

# Conversaciones (opcional pero útil)
class Conversation(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    title = models.CharField(max_length=200)
    created_at = models.DateTimeField(auto_now_add=True)

class Message(models.Model):
    conversation = models.ForeignKey(Conversation, on_delete=models.CASCADE)
    content = models.TextField()
    is_user = models.BooleanField(default=True)
    timestamp = models.DateTimeField(auto_now_add=True)
    class Meta:
        ordering = ['timestamp']

# FAQ / KB “rápida”
class FAQCategory(models.Model):
    name = models.CharField(max_length=120, unique=True)
    slug = models.SlugField(max_length=140, unique=True)
    def __str__(self): return self.name

class FAQ(models.Model):
    LANG_CHOICES = [("es","Español"), ("en","English")]
    question_canonical = models.CharField(max_length=300, unique=True)
    answer_html = models.TextField()
    language = models.CharField(max_length=5, choices=LANG_CHOICES, default="es")
    tags = models.JSONField(default=list, blank=True)
    is_active = models.BooleanField(default=True)
    tenant = models.CharField(max_length=64, null=True, blank=True, db_index=True)  # "A" | "B" | None
    category = models.ForeignKey(FAQCategory, null=True, blank=True, on_delete=models.SET_NULL, related_name="faqs")
    action = models.JSONField(null=True, blank=True)  # ej: {"type":"abrir_formulario","target":"registro_donante"}

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)
    def __str__(self): return self.question_canonical

class FAQSynonym(models.Model):
    faq = models.ForeignKey(FAQ, on_delete=models.CASCADE, related_name="synonyms")
    text = models.CharField(max_length=300, db_index=True)
    class Meta: unique_together = [("faq","text")]

class FAQRegex(models.Model):
    faq = models.ForeignKey(FAQ, on_delete=models.CASCADE, related_name="regexes")
    pattern = models.CharField(max_length=255)
    flags = models.CharField(max_length=16, default="i")

    class Meta:
        constraints = [
            models.UniqueConstraint(fields=["faq", "pattern"], name="uniq_faq_pattern")
        ]

# Feedback
class ChatFeedback(models.Model):
    user = models.ForeignKey(User, on_delete=models.CASCADE)
    comment = models.TextField()
    tenant = models.CharField(max_length=32, null=True, blank=True, db_index=True)  # "A" | "B"
    conversation = models.ForeignKey(Conversation, null=True, blank=True, on_delete=models.SET_NULL)
    route = models.CharField(max_length=40, null=True, blank=True)  # faq_exact / semantic_direct / rag / llm
    extra = models.JSONField(null=True, blank=True)  # scores, sources, etc.
    created_at = models.DateTimeField(auto_now_add=True)
    def __str__(self):
        t = f"[{self.tenant}] " if self.tenant else ""
        return f"{t}{self.user.username}: {self.comment[:30]}"