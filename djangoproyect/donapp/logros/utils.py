from .models import Achievement, UserProgress, UserAchievement, UserItem, Items
from django.utils import timezone
from django.db import transaction

def check_and_unlock_achievement(user, slug_key, count_increment=1):
    # 1. Busca la definición del logro.
    print(f"check_and_unlock_achievement called with user={user.username}, slug_key={slug_key}, count_increment={count_increment}")
    try:
        achievement = Achievement.objects.get(slug=slug_key)
    except Achievement.DoesNotExist:
        return {"status": "not_found", "message": "Logro no encontrado"} # Logro no existe.
    
    print (f"Achievement found: {achievement}")
    # 2. Verifica si el usuario ya lo tiene.
    if UserAchievement.objects.filter(user=user, achievement=achievement).exists():
        return {"status": "already_unlocked", "message": "Logro ya desbloqueado", "achievement_name": achievement.name} # Ya desbloqueado.

    # 3. Actualiza el progreso o establece el conteo si es necesario.
    progress, created = UserProgress.objects.get_or_create(
        user=user,
        achievement_slug=slug_key,
        defaults={'current_count': 0}
    )

    # Solo incrementa si es un logro de conteo o si es la primera vez para un logro simple (count_increment=1).
    if achievement.required_count > 1 or created:
        progress.current_count += count_increment
        progress.save()

    # 4. Comprueba si el logro ha sido alcanzado.
    if progress.current_count >= achievement.required_count:
        # ¡Logro desbloqueado!
        print(f"Unlocking achievement '{achievement.name}' for user {user.username}")
        UserAchievement.objects.create(user=user, achievement=achievement)
        #progress.delete() # Limpia el progreso para este logro.
        return {"status": "unlocked", "message": "¡Logro desbloqueado!", "achievement_name": achievement.name} # Retorna True para notificar al frontend (Flutter).

    return {"status": "in_progress", "message": "Progreso actualizado", "achievement_name": achievement, "progress": achievement} # Progreso actualizado, pero no desbloqueado aún.


def otorgar_item(user, slug, cantidad=1):
    # Primero verifica que exista el Items con ese slug
    from .models import Items, UserItem

    try:
        item = Items.objects.get(slug=slug)
    except Items.DoesNotExist:
        raise ValueError(f"Item con slug '{slug}' no existe.")
    
    with transaction.atomic():
        user_item, created = UserItem.objects.get_or_create(user=user, item_slug=slug)
        user_item.cantidad += cantidad
        user_item.last_awarded = timezone.now()
        user_item.save()

    return user_item

def canjear_item(user, slug, cantidad=1):
    from .models import Items, UserItem

    # Opcionalmente, primero verifica que exista un Items con ese slug
    try:
        Items.objects.get(slug=slug)
    except Items.DoesNotExist:
        raise ValueError(f"Item con slug '{slug}' no existe.")

    try:
        user_item = UserItem.objects.get(user=user, item_slug=slug)
    except UserItem.DoesNotExist:
        raise ValueError(f"Usuario no tiene el item '{slug}'.")

    if user_item.cantidad < cantidad:
        raise ValueError("Cantidad insuficiente para canjear")

    with transaction.atomic():
        user_item.cantidad -= cantidad
        if user_item.cantidad == 0:
            user_item.delete()
        else:
            user_item.save()
    return user_item

