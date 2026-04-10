import random
from django.db import migrations, models
import random

def set_default_edad(apps, schema_editor):
    UserProfile = apps.get_model("usuarios", "UserProfile")
    for profile in UserProfile.objects.filter(edad__isnull=True):
        # Edad determinística entre 18 y 50
        random.seed(profile.id)
        profile.edad = random.randint(18, 50)
        profile.save(update_fields=["edad"])

class Migration(migrations.Migration):

    dependencies = [
        ('usuarios', '0002_create_test_users'),
    ]

    operations = [
        # 1. Agregar campo permitiendo NULLs temporalmente
        migrations.AddField(
            model_name='userprofile',
            name='edad',
            field=models.PositiveIntegerField(null=True),
        ),
        # 2. Poblar los valores
        migrations.RunPython(set_default_edad),
        # 3. Hacer el campo obligatorio
        migrations.AlterField(
            model_name='userprofile',
            name='edad',
            field=models.PositiveIntegerField(null=False, default=18),
        ),
    ]
