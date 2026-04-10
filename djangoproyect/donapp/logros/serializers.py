from rest_framework import serializers
from .models import Achievement, UserAchievement, UserProgress, UserItem, Items




class AchievementSerializer(serializers.ModelSerializer):
    unlocked = serializers.SerializerMethodField()
    current_count = serializers.SerializerMethodField()
    icon_url = serializers.SerializerMethodField()

    class Meta:
        model = Achievement
        fields = ['id', 'name', 'slug', 'description', 'required_count', 'icon_url','unlocked', 'current_count']

    def get_unlocked(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if not user or not user.is_authenticated:
            return False
        return UserAchievement.objects.filter(user=user, achievement=obj).exists()

    def get_current_count(self, obj):
        user = self.context.get('request').user if self.context.get('request') else None
        if not user or not user.is_authenticated:
            return 0
        progress = UserProgress.objects.filter(user=user, achievement_slug=obj.slug).first()
        return progress.current_count if progress else 0

    
    def get_icon_url(self, obj):
        request = self.context.get('request')
        if obj.icon and hasattr(obj.icon, 'url') and request:
            return request.build_absolute_uri(obj.icon.url)
        return None

class ItemsSerializer(serializers.ModelSerializer):
    class Meta:
        model = Items
        fields = ['id', 'name', 'slug', 'value', 'description', 'icon', 'canjeable']

class UserItemSerializer(serializers.ModelSerializer):
    item = serializers.SerializerMethodField()

    class Meta:
        model = UserItem
        fields = ['id', 'item', 'cantidad', 'last_awarded']

    def get_item(self, obj):
        try:
            item_obj = Items.objects.get(slug=obj.item_slug)
            return ItemsSerializer(item_obj, context=self.context).data
        except Items.DoesNotExist:
            return None