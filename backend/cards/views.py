from drf_spectacular.utils import extend_schema, OpenApiResponse
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny

from .serializers import CardSerializer, CardListSerializer
from .models import Card


class GetCard(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        summary='Получение карт по ID',
        description="Возвращает информацию о карте ID.",
        responses={
            200: OpenApiResponse(response=CardSerializer, description="Информация о карте"),
            404: OpenApiResponse(description="Карта не найдена")
        }
    )
    def get(self, request, card_id):
        try:
            card = Card.objects.prefetch_related('inventory').get(id=card_id)
        except Card.DoesNotExist:
            return Response({'error': 'Карта не найдена'}, status=status.HTTP_404_NOT_FOUND)

        serializer = CardSerializer(card)
        return Response(serializer.data)


class GetCards(APIView):
    permission_classes = [AllowAny]

    @extend_schema(
        summary='Получение карт по совпадению названия',
        description="Возвращает карты по названию.",
        responses={
            200: OpenApiResponse(response=CardListSerializer, description="Карты по названию"),
            404: OpenApiResponse(description="Карты не найдены")
        }
    )
    def get(self, request, card_name):
        cards = Card.objects.filter(name__icontains=card_name).prefetch_related('inventory')

        serializer = CardSerializer(cards, many=True)
        return Response({'counter': len(serializer.data), 'cards': serializer.data})
