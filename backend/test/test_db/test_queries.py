import pytest
from backend.src.db._queries import TABLE_CREATE


class TestQueries:
    def test_table_create_queries_exist(self):
        """Тест наличия всех необходимых таблиц"""
        expected_tables = [
            'cards',
            'users',
            'card_inventory',
            'orders',
            'order_items',
            'cart_items',
            'card_requests',
            'password_resets'
        ]

        for table in expected_tables:
            assert table in TABLE_CREATE
            assert isinstance(TABLE_CREATE[table], str)
            assert 'CREATE TABLE' in TABLE_CREATE[table]

    def test_cards_table_structure(self):
        """Тест структуры таблицы cards"""
        query = TABLE_CREATE['cards']
        required_columns = [
            'id SERIAL PRIMARY KEY',
            'color VARCHAR',
            'set_code VARCHAR',
            'collector_number VARCHAR',
            'name VARCHAR',
            'image_url'
        ]

        for column in required_columns:
            assert any(col in query for col in column.split())

    def test_users_table_structure(self):
        """Тест структуры таблицы users"""
        query = TABLE_CREATE['users']
        required_columns = [
            'email VARCHAR',
            'password_hash',
            'username',
            'role',
            'telegram'
        ]

        for column in required_columns:
            assert column in query or any(col in query for col in column.split())