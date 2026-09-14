import pytest
import json
from unittest.mock import Mock, patch, mock_open
from backend.src.db._cards import add_cards_from_file, transform_card_data, search_card
from backend.src.db._cards import search_cards_with_inventory


class TestCards:
    def test_transform_card_data_blue(self):
        """Тест преобразования синей карты"""
        mock_self = Mock()
        card_data = {
            'color_identity': ['U'],
            'type_line': 'Instant',
            'set': 'MH3',
            'set_name': 'Modern Horizons 3',
            'collector_number': '134',
            'name': 'Counterspell',
            'image_uris': {
                'small': 'http://test.com/small.jpg',
                'normal': 'http://test.com/normal.jpg',
                'large': 'http://test.com/large.jpg'
            }
        }

        result = transform_card_data(mock_self, card_data)

        assert result['color'] == 'Blue'
        assert result['set_code'] == 'MH3'
        assert result['name'] == 'Counterspell'
        assert result['card_type'] == 'Instant'

    def test_transform_card_data_multicolor(self):
        """Тест преобразования мультиколорной карты"""
        mock_self = Mock()
        card_data = {
            'color_identity': ['W', 'U'],
            'type_line': 'Creature',
            'set': 'MH3',
            'set_name': 'Modern Horizons 3',
            'collector_number': '135',
            'name': 'Multicolor Creature',
            'image_uris': {}
        }

        result = transform_card_data(mock_self, card_data)

        assert result['color'] == 'Multicolor'

    def test_transform_card_colorless(self):
        """Тест преобразования бесцветной карты"""
        mock_self = Mock()
        card_data = {
            'color_identity': [],
            'type_line': 'Artifact',
            'set': 'MH3',
            'set_name': 'Modern Horizons 3',
            'collector_number': '136',
            'name': 'Colorless Artifact',
            'image_uris': {}
        }

        result = transform_card_data(mock_self, card_data)

        assert result['color'] == 'Colorless'

    @patch('builtins.open', new_callable=mock_open, read_data='[{"name": "Test Card"}]')
    @patch('backend.src.db._cards.tqdm')
    def test_add_cards_from_file(self, mock_tqdm, mock_file, mock_cursor):
        """Тест добавления карт из файла"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_self.transform_card_data.return_value = {
            'color': 'Blue',
            'set_code': 'TEST',
            'set_name': 'Test Set',
            'collector_number': '1',
            'name': 'Test Card',
            'card_type': 'Creature',
            'image_url_small': '',
            'image_url_normal': '',
            'image_url_large': ''
        }

        add_cards_from_file(mock_self, mock_cursor, 'test.json')

        mock_cursor.execute.assert_called()

    def test_search_card(self, mock_cursor):
        """Тест поиска карт"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchall.return_value = [('card1',), ('card2',)]

        count, cards = search_card(mock_self, mock_cursor, "test")

        assert count == 2
        assert len(cards) == 2
        mock_cursor.execute.assert_called_with(
            "SELECT * FROM cards WHERE name ILIKE %s;",
            ("%test%",)
        )

    def test_search_cards_with_inventory(self, mock_cursor):
        """Тест поиска карт с инвентарем"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchall.return_value = [('card1',), ('card2',)]

        count, cards = search_cards_with_inventory(mock_self, mock_cursor, "test")

        assert count == 2
        assert len(cards) == 2
        # Проверяем, что запрос содержит LEFT JOIN
        call_args = mock_cursor.execute.call_args[0][0]
        assert "LEFT JOIN card_inventory" in call_args