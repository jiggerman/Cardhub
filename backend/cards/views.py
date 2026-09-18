from django.db.models import Q
from drf_spectacular.utils import extend_schema, OpenApiResponse
from rest_framework import status
from rest_framework.response import Response
from rest_framework.views import APIView
from rest_framework.permissions import AllowAny

from .serializers import CardFilterSerializer, CardSerializer, CardListSerializer
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
        parameters=[CardFilterSerializer],
        responses={
            200: OpenApiResponse(response=CardListSerializer, description="Карты по названию"),
            404: OpenApiResponse(description="Карты не найдены")
        }
    )
    def get(self, request, card_name):
        filter_serializer = CardFilterSerializer(data=request.query_params)
        filter_serializer.is_valid(raise_exception=True)
        filters = filter_serializer.validated_data

        cards = Card.objects.filter(name__icontains=card_name)
        if filters.get('color'):
            cards = cards.filter(color=filters['color'])

        inventory_filter_requested = (
            filters.get('in_stock') is True
            or any(key in filters for key in ('quality', 'min_price', 'max_price'))
        )
        if inventory_filter_requested:
            inventory_filter = Q(inventory__quantity__gt=0)
            if filters.get('quality'):
                inventory_filter &= Q(inventory__quality=filters['quality'])
            if 'min_price' in filters:
                inventory_filter &= Q(inventory__price__gte=filters['min_price'])
            if 'max_price' in filters:
                inventory_filter &= Q(inventory__price__lte=filters['max_price'])
            cards = cards.filter(inventory_filter).distinct()

        cards = cards.prefetch_related('inventory')

        serializer = CardSerializer(cards, many=True)
        return Response({'counter': len(serializer.data), 'cards': serializer.data})
