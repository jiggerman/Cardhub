from rest_framework import serializers
from .models import Card


class CardSerializer(serializers.ModelSerializer):
    in_stock = serializers.SerializerMethodField()
    min_price = serializers.SerializerMethodField()
    available_qualities = serializers.SerializerMethodField()

    class Meta:
        model = Card
        fields = ('id', 'color', 'set_code', 'set_name', 'collection_number', 'name', 'card_type', 'image_url_small',
                 'image_url_normal', 'image_url_large', 'created_at', 'updated_at',
                 'in_stock', 'min_price', 'available_qualities'
                 )

    def _in_stock_items(self, card):
        # Полагаемся на prefetch_related('inventory') во view, чтобы не бить в БД на каждую карту
        return [item for item in card.inventory.all() if item.quantity > 0]

    def get_in_stock(self, card):
        return sum(item.quantity for item in self._in_stock_items(card))

    def get_min_price(self, card):
        prices = [item.price for item in self._in_stock_items(card)]
        return float(min(prices)) if prices else None

    def get_available_qualities(self, card):
        return sorted({item.quality for item in self._in_stock_items(card)})


class CardListSerializer(serializers.Serializer):
    counter = serializers.IntegerField()
    cards = CardSerializer(many=True)
