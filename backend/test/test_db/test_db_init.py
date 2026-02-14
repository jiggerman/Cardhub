import pytest
from unittest.mock import Mock, patch, MagicMock
import psycopg2
from backend.src.db import Database


class TestDatabaseInit:
    @patch('psycopg2.connect')
    def test_conn_property_success(self, mock_connect):
        """Тест успешного подключения к БД"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn

        db = Database()
        conn = db.conn

        assert conn == mock_conn
        mock_connect.assert_called_once()

    @patch('psycopg2.connect')
    def test_conn_property_cached(self, mock_connect):
        """Тест кэширования подключения"""
        mock_conn = MagicMock()
        mock_connect.return_value = mock_conn

        db = Database()
        conn1 = db.conn
        conn2 = db.conn

        assert conn1 == conn2
        mock_connect.assert_called_once()

    @patch('psycopg2.connect')
    def test_conn_property_reconnect_on_closed(self, mock_connect):
        """Тест переподключения при закрытом соединении"""
        mock_conn = MagicMock()
        mock_conn.closed = True
        mock_connect.return_value = mock_conn

        db = Database()
        db._conn = mock_conn

        conn = db.conn

        assert conn == mock_conn
        assert mock_connect.call_count == 2  # Первый вызов + повторный

    def test_context_manager(self):
        """Тест контекстного менеджера"""
        mock_conn = MagicMock()
        mock_conn.closed = False

        with patch.object(Database, 'conn', mock_conn):
            db = Database()
            db._conn = mock_conn

            with db as d:
                assert d == db

            mock_conn.commit.assert_called_once()
            mock_conn.close.assert_called_once()

    def test_context_manager_with_exception(self):
        """Тест контекстного менеджера с ошибкой"""
        mock_conn = MagicMock()
        mock_conn.closed = False

        with patch.object(Database, 'conn', mock_conn):
            db = Database()
            db._conn = mock_conn

            with pytest.raises(ValueError):
                with db:
                    raise ValueError("Test error")

            mock_conn.rollback.assert_called_once()
            mock_conn.close.assert_called_once()

    def test_cursor_context_manager(self, mock_conn):
        """Тест контекстного менеджера курсора"""
        mock_cursor = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor

        db = Database()
        db._conn = mock_conn

        with db.cursor() as cursor:
            assert cursor == mock_cursor

        mock_conn.commit.assert_called_once()
        mock_cursor.close.assert_called_once()

    @patch('psycopg2.connect')
    def test_create_tables(self, mock_connect, mock_cursor):
        """Тест создания таблиц"""
        mock_conn = MagicMock()
        mock_conn.cursor.return_value.__enter__.return_value = mock_cursor
        mock_connect.return_value = mock_conn

        db = Database()
        db.create_tables()

        # Проверяем, что execute вызывался для каждой таблицы
        assert mock_cursor.execute.call_count == len(TABLE_CREATE)