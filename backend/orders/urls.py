from django.urls import path
from .views import CreateOrder

urlpatterns = [
    path('orders/', CreateOrder.as_view(), name='create-order'),
]

