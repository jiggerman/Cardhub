from rest_framework import serializers
from .models import Order, OrderItem, OrderType


class OrderSerializer(serializers.ModelSerializer):
    class Meta:
        model = Order
        fields = ('orderType', 'user', 'status', 'shipping_method', 'tracking_number', 'shipping_address',
                  'created_at', 'paid_at', 'assembled_at', 'delivered_at')
        read_only_fields = ('created_at', 'paid_at', 'assembled_at', 'delivered_at')

    def validate_orterType(self, value):
        allowed_types = [item[0] for item in OrderType.choices]

        if value not in allowed_types:
            raise serializers.ValidationError(
                f'Недопустимый тип заказа: {value}. '
                f'Допустимые типы: {", ".join(allowed_types)}'
            )

        return value


class OrderItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = OrderItem
        fields = ('order', 'card_inventory', 'quantity', 'unit_price')
        read_only_fields = ('subtotal', 'order')


class CreateOrderSerializer(serializers.Serializer):
    order = OrderSerializer()
    cards = OrderItemSerializer(many=True)

    def create(self, validated_data):
        order_data = validated_data.pop('order')
        items_data = validated_data.pop('cards')

        order = Order.objects.create(**order_data)
        for item_data in items_data:
            item_data.pop('order', None)
            OrderItem.objects.create(order=order, **item_data)

        return order
