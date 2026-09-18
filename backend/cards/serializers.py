from rest_framework import serializers
from drf_spectacular.utils import extend_schema_field
from .models import Card


class CardOfferSerializer(serializers.Serializer):
    id = serializers.IntegerField()
    quality = serializers.CharField()
    lang = serializers.CharField()
    foil = serializers.BooleanField()
    quantity = serializers.IntegerField()
    price = serializers.DecimalField(max_digits=10, decimal_places=2)


class CardSerializer(serializers.ModelSerializer):
    in_stock = serializers.SerializerMethodField()
    min_price = serializers.SerializerMethodField()
    available_qualities = serializers.SerializerMethodField()
    offers = serializers.SerializerMethodField()

    class Meta:
        model = Card
        fields = ('id', 'color', 'set_code', 'set_name', 'collection_number', 'name', 'card_type', 'image_url_small',
                 'image_url_normal', 'image_url_large', 'created_at', 'updated_at',
                 'in_stock', 'min_price', 'available_qualities', 'offers'
                 )

    def _in_stock_items(self, card):
        # Полагаемся на prefetch_related('inventory') во view, чтобы не бить в БД на каждую карту
        return [item for item in card.inventory.all() if item.quantity > 0]

    def get_in_stock(self, card) -> int:
        return sum(item.quantity for item in self._in_stock_items(card))

    def get_min_price(self, card) -> float | None:
        prices = [item.price for item in self._in_stock_items(card)]
        return float(min(prices)) if prices else None

    def get_available_qualities(self, card) -> list[str]:
        return sorted({item.quality for item in self._in_stock_items(card)})

    @extend_schema_field(CardOfferSerializer(many=True))
    def get_offers(self, card):
        items = sorted(
            card.inventory.all(),
            key=lambda item: (item.quantity <= 0, item.price, item.quality, item.id),
        )
        return CardOfferSerializer(items, many=True).data


class CardListSerializer(serializers.Serializer):
    counter = serializers.IntegerField()
    cards = CardSerializer(many=True)


class CardFilterSerializer(serializers.Serializer):
    color = serializers.ChoiceField(choices=Card.COLOR_CHOICES, required=False)
    quality = serializers.ChoiceField(
        choices=['NM', 'SP', 'MP', 'HP', 'DM'], required=False
    )
    in_stock = serializers.BooleanField(required=False)
    min_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False
    )
    max_price = serializers.DecimalField(
        max_digits=10, decimal_places=2, min_value=0, required=False
    )

    def validate(self, attrs):
        min_price = attrs.get('min_price')
        max_price = attrs.get('max_price')
        if min_price is not None and max_price is not None and min_price > max_price:
            raise serializers.ValidationError({
                'max_price': 'Максимальная цена должна быть не меньше минимальной'
            })
        return attrs
