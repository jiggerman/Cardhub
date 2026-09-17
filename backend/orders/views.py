from drf_spectacular.utils import extend_schema, OpenApiResponse
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import IsAuthenticated

from .serializers import OrderSerializer, CreateOrderSerializer
from .models import Order

class CreateOrder(APIView):
    permission_classes = [IsAuthenticated]

    @extend_schema(
        summary='Список заказов текущего пользователя',
        responses={200: OrderSerializer(many=True)},
    )
    def get(self, request):
        orders = Order.objects.filter(user=request.user).prefetch_related('items__card').order_by('-created_at')
        return Response(OrderSerializer(orders, many=True).data)

    @extend_schema(
        summary='Создание заказа',
        description='',
        request=CreateOrderSerializer,
        responses={
            201: OpenApiResponse(response=OrderSerializer, description='Заказ создан'),
            400: OpenApiResponse(description='Ошибка валидации данных'),
        }
    )
    def post(self, request):
        serializer = CreateOrderSerializer(data=request.data, context={'request': request})
        if serializer.is_valid():
            order = serializer.save()
            return Response(OrderSerializer(order).data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

