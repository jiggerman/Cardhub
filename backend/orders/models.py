from django.db import models, transaction
from django.dispatch import receiver
from django.db.models.signals import post_delete

from inventory.models import CardInventory
from django.db.models import F


class OrderType(models.TextChoices):
    PURCHASE = 'purchase', 'Покупка (в наличии)'
    IMPORT = 'import', 'Заказ (под заказ у партнера)'
    RESERVATION = 'reservation', 'Предзаказ (бронь)'


class OrderStatus(models.TextChoices):
    PENDING = 'pending', 'Ожидает оплаты'
    ASSEMBLY = 'assembly', 'Сборка'
    IN_TRANSIT = 'in_transit', 'В доставке'
    DELIVERED = 'delivered', 'Доставлен'
    CANCELLED = 'cancelled', 'Отменен'

    VERIFICATION = 'verification', 'Сверка позиций (Import)'
    SHIPPING_PARTNER_TO_SPB = 'shipping_to_spb', 'Отправка Сайт СПБ (Import)'
    NOTIFIED = 'notified', 'Уведомление клиента (Reservation)'
    UNDER_CONSIDERATION = 'under_consideration', 'На рассмотрении (Reservation)'


class Order(models.Model):
    orderType = models.CharField(max_length=20, choices=OrderType.choices)
    user = models.ForeignKey('users.User', on_delete=models.PROTECT, related_name='orders')
    status = models.CharField(max_length=30, choices=OrderStatus.choices, blank=True)

    shipping_method = models.CharField(max_length=50, blank=True)
    tracking_number = models.CharField(max_length=100, blank=True, null=True)
    shipping_address = models.JSONField(null=True, blank=True)

    created_at = models.DateTimeField(auto_now_add=True)
    paid_at = models.DateTimeField(null=True, blank=True)
    assembled_at = models.DateTimeField(null=True, blank=True)
    delivered_at = models.DateTimeField(null=True, blank=True)

    def save(self, *args, **kwargs):
        if self._state.adding:
            if self.orderType == 'purchase':
                self.status = 'pending'
            elif self.orderType == 'import':
                self.status = 'verification'
            elif self.orderType == 'reservation':
                self.status = 'under_consideration'
        return super().save(*args, **kwargs)


class OrderItem(models.Model):
    order = models.ForeignKey(Order, on_delete=models.CASCADE, related_name='items')
    card = models.ForeignKey('cards.Card', on_delete=models.PROTECT, related_name='order_items')
    card_inventory = models.ForeignKey(
        'inventory.CardInventory', on_delete=models.PROTECT, null=True, blank=True
    )
    quality = models.CharField(max_length=5, default='NM')
    quantity = models.PositiveIntegerField()
    unit_price = models.DecimalField(max_digits=10, decimal_places=2, null=True, blank=True)

    subtotal = models.GeneratedField(
        expression=F('quantity') * F('unit_price'),
        output_field=models.DecimalField(max_digits=10, decimal_places=2),
        db_persist=True,
    )

    @property
    def is_price_pending(self):
        """Цена ожидает уточнения"""
        return self.unit_price is None

    @property
    def display_subtotal(self):
        if self.unit_price is None:
            return "Цена уточняется"
        return self.subtotal

    def save(self, *args, **kwargs):
        if self._state.adding and self.order.orderType == 'purchase':
            if not self.card_inventory_id:
                raise ValueError('Для покупки необходимо выбрать складскую позицию')
            with transaction.atomic():
                card_inventory = CardInventory.objects.select_for_update().get(id=self.card_inventory_id)
                res_quantity = card_inventory.quantity - self.quantity
                if res_quantity < 0:
                    raise ValueError(
                        f'В наличии недостаточно карт {card_inventory.name}. '
                        f'Доступно: {card_inventory.quantity}, запрошено: {self.quantity}'
                    )

                card_inventory.quantity = F('quantity') - self.quantity
                card_inventory.save(update_fields=['quantity'])

        return super().save(*args, **kwargs)


@receiver(post_delete, sender=OrderItem)
def return_inventory_cards(sender, instance, **kwargs):
    if instance.order.orderType == 'purchase' and instance.card_inventory_id:
        with transaction.atomic():
            card_inventory = CardInventory.objects.select_for_update().get(id=instance.card_inventory_id)
            card_inventory.quantity = F('quantity') + instance.quantity
            card_inventory.save(update_fields=['quantity'])
