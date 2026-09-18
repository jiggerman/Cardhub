from decimal import Decimal

from rest_framework.test import APITestCase

from inventory.models import CardInventory
from users.models import User

from .models import Card


class CardFilterTests(APITestCase):
    def setUp(self):
        owner = User.objects.create_user(
            email='seller@example.com', password='strong-password-123'
        )
        self.available = self.create_card(
            owner, name='Test Ring Alpha', color='Colorless', quality='NM',
            quantity=2, price='100.00', collection_number='1',
        )
        self.other_offer = self.create_card(
            owner, name='Test Ring Beta', color='White', quality='SP',
            quantity=1, price='200.00', collection_number='2',
        )
        self.unavailable = self.create_card(
            owner, name='Test Ring Gamma', color='Colorless', quality='NM',
            quantity=0, price='50.00', collection_number='3',
        )

    def create_card(self, owner, *, quality, quantity, price, **card_fields):
        card = Card.objects.create(
            set_code='TST', set_name='Test Set', card_type='Artifact', **card_fields
        )
        CardInventory.objects.create(
            card=card, owner=owner, quality=quality, quantity=quantity,
            price=Decimal(price),
        )
        return card

    def test_search_without_filters_keeps_existing_behavior(self):
        response = self.client.get('/api/cards/Test Ring')
        self.assertEqual(response.status_code, 200)
        self.assertEqual(response.data['counter'], 3)

    def test_combines_color_quality_stock_and_price_filters(self):
        response = self.client.get('/api/cards/Test Ring', {
            'color': 'Colorless',
            'quality': 'NM',
            'in_stock': 'true',
            'min_price': '90',
            'max_price': '110',
        })
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data['counter'], 1)
        self.assertEqual(response.data['cards'][0]['id'], self.available.id)

    def test_quality_filter_ignores_unavailable_inventory(self):
        response = self.client.get('/api/cards/Test Ring', {'quality': 'NM'})
        self.assertEqual(response.status_code, 200, response.data)
        self.assertEqual(response.data['counter'], 1)
        self.assertEqual(response.data['cards'][0]['id'], self.available.id)

    def test_rejects_invalid_price_range(self):
        response = self.client.get('/api/cards/Test Ring', {
            'min_price': '200', 'max_price': '100',
        })
        self.assertEqual(response.status_code, 400)
