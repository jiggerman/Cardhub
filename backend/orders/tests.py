from decimal import Decimal

from rest_framework.test import APITestCase

from cards.models import Card
from inventory.models import CardInventory
from orders.models import Order, OrderItem
from users.models import User


class StorefrontApiTests(APITestCase):
    def setUp(self):
        self.user = User.objects.create_user(email='buyer@example.com', password='strong-password-123')
        self.card = Card.objects.create(
            color='Colorless', set_code='TST', set_name='Test Set', collection_number='1',
            name='Test Ring', card_type='Artifact', image_url_small='https://example.com/s.jpg',
            image_url_normal='https://example.com/n.jpg', image_url_large='https://example.com/l.jpg',
        )
        self.inventory = CardInventory.objects.create(
            card=self.card, quality='NM', quantity=3, price=Decimal('199.00'), owner=self.user,
        )

    def test_card_search_exposes_orderable_offer(self):
        response = self.client.get('/api/cards/Test')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['cards'][0]['offers'][0]['id'], self.inventory.id)
        self.assertEqual(response.data['cards'][0]['in_stock'], 3)

    def test_authenticated_user_can_create_and_list_purchase(self):
        self.client.force_authenticate(self.user)
        payload = {
            'order': {
                'orderType': 'purchase', 'shipping_method': 'cdek',
                'shipping_address': {'address': 'Санкт-Петербург'},
            },
            'cards': [{
                'card': self.card.id, 'card_inventory': self.inventory.id,
                'quality': 'NM', 'quantity': 2,
            }],
        }
        created = self.client.post('/api/orders/', payload, format='json')
        self.assertEqual(created.status_code, 201, created.data)
        self.assertEqual(Order.objects.get().user, self.user)
        self.assertEqual(OrderItem.objects.get().unit_price, Decimal('199.00'))
        self.inventory.refresh_from_db()
        self.assertEqual(self.inventory.quantity, 1)

        listed = self.client.get('/api/orders/')
        self.assertEqual(listed.status_code, 200)
        self.assertEqual(listed.data[0]['items'][0]['card']['name'], 'Test Ring')

    def test_reservation_does_not_require_inventory(self):
        self.client.force_authenticate(self.user)
        response = self.client.post('/api/orders/', {
            'order': {'orderType': 'reservation', 'shipping_method': 'pickup'},
            'cards': [{'card': self.card.id, 'quality': 'SP', 'quantity': 1}],
        }, format='json')
        self.assertEqual(response.status_code, 201, response.data)
        self.assertIsNone(OrderItem.objects.get().card_inventory)

    def test_profile_shipping_address_can_be_updated(self):
        self.client.force_authenticate(self.user)
        response = self.client.patch('/api/user/me/', {
            'shipping_address': {'address': 'Невский проспект, 1'},
        }, format='json')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['shipping_address']['address'], 'Невский проспект, 1')
