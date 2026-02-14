import pytest
from unittest.mock import Mock, patch


class TestCardsRoutes:
    def test_search_cards_success(self, client, app, sample_card_data):
        """Тест успешного поиска карт"""
        with app.app_context():
            app.db.search_card.return_value = (1, [sample_card_data])

            response = client.get('/api/cards/search/Test%20Card')

            assert response.status_code == 200
            data = response.json
            assert len(data) == 2  # (count, cards)
            assert data[1][0]['name'] == 'Test Card'

    def test_search_cards_empty(self, client, app):
        """Тест поиска без результатов"""
        with app.app_context():
            app.db.search_card.return_value = (0, [])

            response = client.get('/api/cards/search/NonExistent')

            assert response.status_code == 200
            data = response.json
            assert data[0] == 0
            assert data[1] == []

    def test_search_cards_error(self, client, app):
        """Тест ошибки при поиске карт"""
        with app.app_context():
            app.db.search_card.side_effect = Exception("DB Error")

            response = client.get('/api/cards/search/Test')

            assert response.status_code == 500
            assert 'error' in response.json