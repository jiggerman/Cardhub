import pytest
from unittest.mock import Mock, patch
from backend.src.db._common import with_cursor


def test_with_cursor_decorator():
    """Тест декоратора with_cursor"""
    mock_self = Mock()
    mock_self.cursor.return_value.__enter__.return_value = "test_cursor"

    @with_cursor
    def test_func(self, cursor, arg1, arg2):
        assert cursor == "test_cursor"
        assert arg1 == "test1"
        assert arg2 == "test2"
        return "success"

    result = test_func(mock_self, "test1", "test2")
    assert result == "success"
    mock_self.cursor.assert_called_once()