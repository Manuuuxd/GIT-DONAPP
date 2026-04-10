from django.urls import path
from .views import UserAchievementsView, OtorgarLogroAPI, OtorgarItemAPI, UserItemsList, CanjarItemAPI, ItemsList

urlpatterns = [
    path('user-achievements/', UserAchievementsView.as_view(), name='user-achievements'),
    path('otorgar-logro/', OtorgarLogroAPI.as_view(), name='otorgar-logro'),
    path('otorgar-item/', OtorgarItemAPI.as_view(), name='otorgar-item'),
    path('user-items/', UserItemsList.as_view(), name='user-items'),
    path('canjear-item/', CanjarItemAPI.as_view(), name='canjear-item'),
    path('items/', ItemsList.as_view(), name='items-list'),
]
