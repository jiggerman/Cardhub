import pytest
from unittest.mock import Mock, patch, MagicMock
from backend.src.db._base_user import register_new_user, get_user, get_user_by_id
from backend.src.db._base_user import update_telegram_username, update_username
from backend.src.db._classes import User


class TestBaseUser:
    def test_register_new_user_success(self, mock_cursor):
        """Тест успешной регистрации пользователя"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor

        result = register_new_user(mock_self, mock_cursor,
                                   username="testuser",
                                   email="test@example.com",
                                   password_hash="hashed123")

        assert result is True
        mock_cursor.execute.assert_called_once()
        args = mock_cursor.execute.call_args[0]
        assert args[0] == "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)"
        assert args[1] == ("testuser", "test@example.com", "hashed123")

    def test_register_new_user_failure(self, mock_cursor):
        """Тест ошибки при регистрации"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.execute.side_effect = Exception("DB Error")

        result = register_new_user(mock_self, mock_cursor,
                                   username="testuser",
                                   email="test@example.com",
                                   password_hash="hashed123")

        assert result is False
        mock_self._conn.rollback.assert_called_once()

    def test_get_user_found(self, mock_cursor, sample_user_data):
        """Тест получения существующего пользователя"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchone.return_value = tuple(sample_user_data.values())

        user = get_user(mock_self, mock_cursor, email="test@example.com")

        assert isinstance(user, User)
        assert user.id == sample_user_data['id']
        assert user.email == sample_user_data['email']
        assert user.username == sample_user_data['username']
        mock_cursor.execute.assert_called_with(
            "SELECT * FROM users WHERE email = %s",
            ("test@example.com",)
        )

    def test_get_user_not_found(self, mock_cursor):
        """Тест получения несуществующего пользователя"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchone.return_value = None

        user = get_user(mock_self, mock_cursor, email="notfound@example.com")

        assert user is None

    def test_get_user_by_id(self, mock_cursor, sample_user_data):
        """Тест получения пользователя по ID"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchone.return_value = tuple(sample_user_data.values())

        user = get_user_by_id(mock_self, mock_cursor, uuid=1)

        assert isinstance(user, User)
        assert user.id == 1
        mock_cursor.execute.assert_called_with(
            "SELECT * FROM users WHERE id = %s",
            (1,)
        )

    def test_update_telegram_username(self, mock_cursor):
        """Тест обновления Telegram username"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor

        update_telegram_username(mock_self, mock_cursor, uuid=1, telegram_username="@testuser")

        mock_cursor.execute.assert_called_with(
            "UPDATE users SET telegram_username = %s WHERE id = %s",
            ("@testuser", 1)
        )

    def test_update_username(self, mock_cursor):
        """Тест обновления username"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor

        update_username(mock_self, mock_cursor, uuid=1, username="newusername")

        mock_cursor.execute.assert_called_with(
            "UPDATE users SET username = %s WHERE id = %s",
            ("newusername", 1)
        )