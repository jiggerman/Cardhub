import os
import sys
import pytest
from unittest.mock import Mock, patch, MagicMock
from flask import Flask
from flask_bcrypt import Bcrypt
from flask_jwt_extended import JWTManager
import psycopg2
from psycopg2.extensions import connection as pg_connection

sys.path.insert(0, os.path.abspath(os.path.join(os.path.dirname(__file__), '..')))

from backend.src.db import Database
from backend.src.web_backend.app import create_app


@pytest.fixture
def app():
    """Создает тестовое Flask приложение"""
    app = create_app()
    app.config['TESTING'] = True
    app.config['JWT_SECRET_KEY'] = 'test-secret-key'
    app.config['SECRET_KEY'] = 'test-secret-key'

    # Мокаем базу данных для тестов
    app.db = MagicMock(spec=Database)

    return app


@pytest.fixture
def client(app):
    """Создает тестовый клиент"""
    return app.test_client()


@pytest.fixture
def mock_db():
    """Мок для Database"""
    return MagicMock(spec=Database)


@pytest.fixture
def mock_cursor():
    """Мок для курсора PostgreSQL"""
    cursor = MagicMock()
    cursor.fetchone.return_value = None
    cursor.fetchall.return_value = []
    return cursor


@pytest.fixture
def mock_conn(mock_cursor):
    """Мок для соединения с БД"""
    conn = MagicMock(spec=pg_connection)
    conn.cursor.return_value.__enter__.return_value = mock_cursor
    conn.cursor.return_value = mock_cursor
    return conn


@pytest.fixture
def sample_user_data():
    """Тестовые данные пользователя"""
    return {
        'id': 1,
        'email': 'test@example.com',
        'password_hash': 'hashed_password',
        'username': 'testuser',
        'role': 'user',
        'email_verified': False,
        'email_verification_token': None,
        'telegram_chat_id': None,
        'telegram_username': None,
        'telegram_verified': False,
        'shipping_address': None,
        'created_at': '2024-01-01',
        'updated_at': '2024-01-01'
    }


@pytest.fixture
def sample_card_data():
    """Тестовые данные карты"""
    return {
        'id': 1,
        'color': 'Blue',
        'set_code': 'MH3',
        'set_name': 'Modern Horizons 3',
        'collector_number': '134',
        'name': 'Test Card',
        'card_type': 'Creature',
        'image_url_small': 'http://test.com/small.jpg',
        'image_url_normal': 'http://test.com/normal.jpg',
        'image_url_large': 'http://test.com/large.jpg',
        'created_at': '2024-01-01',
        'updated_at': '2024-01-01'
    }