import pytest
from unittest.mock import Mock, patch
from backend.src.db._tg_bot import get_user_by_telegram_username, is_verified_tg_user, verified_tg_user
from backend.src.db._classes import User


class TestTgBot:
    def test_get_user_by_telegram_username_found(self, mock_cursor, sample_user_data):
        """Тест получения пользователя по Telegram username"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchone.return_value = tuple(sample_user_data.values())

        user = get_user_by_telegram_username(mock_self, mock_cursor, "@testuser")

        assert isinstance(user, User)
        assert user.telegram_username == "@testuser"
        mock_cursor.execute.assert_called_with(
            "SELECT * FROM users WHERE telegram_username = %s",
            ("@testuser",)
        )

    def test_get_user_by_telegram_username_not_found(self, mock_cursor):
        """Тест получения несуществующего пользователя по Telegram"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        mock_cursor.fetchone.return_value = None

        user = get_user_by_telegram_username(mock_self, mock_cursor, "@notfound")

        assert user is None

    def test_is_verified_tg_user_true(self, mock_cursor, sample_user_data):
        """Тест проверки верифицированного Telegram"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        sample_user_data['telegram_verified'] = True
        mock_cursor.fetchone.return_value = tuple(sample_user_data.values())

        result = is_verified_tg_user(mock_self, mock_cursor, "@testuser")

        assert result is True

    def test_is_verified_tg_user_false(self, mock_cursor, sample_user_data):
        """Тест проверки неверифицированного Telegram"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor
        sample_user_data['telegram_verified'] = False
        mock_cursor.fetchone.return_value = tuple(sample_user_data.values())

        result = is_verified_tg_user(mock_self, mock_cursor, "@testuser")

        assert result is False

    def test_verified_tg_user(self, mock_cursor):
        """Тест верификации Telegram пользователя"""
        mock_self = Mock()
        mock_self.cursor.return_value.__enter__.return_value = mock_cursor

        verified_tg_user(mock_self, mock_cursor, telegram_chat_id=12345, uuid=1)

        mock_cursor.execute.assert_called_with(
            "UPDATE users SET telegram_verified = TRUE, telegram_chat_id = %s WHERE id = %s",
            (12345, 1)
        )