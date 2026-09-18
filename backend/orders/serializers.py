from django.db import transaction
from rest_framework import serializers

from cards.models import Card
from inventory.models import CardInventory
from .models import Order, OrderItem, OrderType


class OrderSerializer(serializers.ModelSerializer):
    items = serializers.SerializerMethodField()

    class Meta:
        model = Order
        fields = ('id', 'orderType', 'user', 'status', 'shipping_method', 'tracking_number', 'shipping_address',
                  'created_at', 'paid_at', 'assembled_at', 'delivered_at', 'items')
        read_only_fields = ('id', 'user', 'status', 'tracking_number', 'created_at', 'paid_at',
                            'assembled_at', 'delivered_at', 'items')

    def validate_orderType(self, value):
        allowed_types = [item[0] for item in OrderType.choices]

        if value not in allowed_types:
            raise serializers.ValidationError(
                f'Недопустимый тип заказа: {value}. '
                f'Допустимые типы: {", ".join(allowed_types)}'
            )

        return value

    def get_items(self, order) -> list[dict]:
        return OrderItemReadSerializer(order.items.all(), many=True).data


class OrderItemSerializer(serializers.ModelSerializer):
    card = serializers.PrimaryKeyRelatedField(queryset=Card.objects.all())
    card_inventory = serializers.PrimaryKeyRelatedField(
        queryset=CardInventory.objects.all(), required=False, allow_null=True
    )

    class Meta:
        model = OrderItem
        fields = ('card', 'card_inventory', 'quality', 'quantity')


class OrderItemReadSerializer(serializers.ModelSerializer):
    card = serializers.SerializerMethodField()
    card_inventory = serializers.PrimaryKeyRelatedField(read_only=True)
    subtotal = serializers.DecimalField(max_digits=12, decimal_places=2, read_only=True)

    class Meta:
        model = OrderItem
        fields = ('id', 'card', 'card_inventory', 'quality', 'quantity', 'unit_price', 'subtotal')

    def get_card(self, item):
        card = item.card
        return {
            'id': card.id,
            'name': card.name,
            'set_code': card.set_code,
            'collection_number': card.collection_number,
            'image_url_small': card.image_url_small,
        }


class CreateOrderSerializer(serializers.Serializer):
    order = OrderSerializer()
    cards = OrderItemSerializer(many=True, allow_empty=False)

    def validate(self, attrs):
        order_type = attrs['order']['orderType']
        for item in attrs['cards']:
            inventory = item.get('card_inventory')
            card = item['card']
            if inventory and inventory.card_id != card.id:
                raise serializers.ValidationError({'cards': 'Складская позиция не относится к выбранной карте'})
            if order_type == OrderType.PURCHASE:
                if not inventory:
                    raise serializers.ValidationError({'cards': 'Для покупки выберите складскую позицию'})
                if inventory.quantity < item['quantity']:
                    raise serializers.ValidationError({'cards': f'Недостаточно карты «{card.name}» в наличии'})
        return attrs

    @transaction.atomic
    def create(self, validated_data):
        order_data = validated_data.pop('order')
        items_data = validated_data.pop('cards')

        order = Order.objects.create(user=self.context['request'].user, **order_data)
        for item_data in items_data:
            inventory = item_data.get('card_inventory')
            if order.orderType == OrderType.PURCHASE:
                item_data['card'] = inventory.card
                item_data['quality'] = inventory.quality
            item_data['unit_price'] = inventory.price if order.orderType == OrderType.PURCHASE else None
            try:
                OrderItem.objects.create(order=order, **item_data)
            except ValueError as error:
                raise serializers.ValidationError({'cards': str(error)}) from error

        return order
