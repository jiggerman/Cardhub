from django.urls import path
from .views import GetCard, GetCards

urlpatterns = [
    path('card/<int:card_id>', GetCard.as_view(), name='get-card'),
    path('cards/<str:card_name>', GetCards.as_view(), name='get-cards')
]

