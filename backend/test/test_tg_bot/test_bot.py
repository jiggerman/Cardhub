import pytest
from unittest.mock import Mock, AsyncMock, patch
from aiogram.types import Message, User as TgUser, Chat
from backend.src.tg_bot.bot import router, create_main_keyboard, Form


@pytest.fixture
def mock_message():
    """Создает мок сообщения для тестов"""
    message = AsyncMock(spec=Message)
    message.from_user = Mock(spec=TgUser)
    message.from_user.username = "testuser"
    message.from_user.id = 12345
    message.chat = Mock(spec=Chat)
    message.chat.id = 12345
    message.text = ""
    message.answer = AsyncMock()
    return message


@pytest.mark.asyncio
async def test_cmd_start(mock_message):
    """Тест команды /start"""
    with patch('backend.src.tg_bot.bot.db') as mock_db:
        mock_db.is_verified_tg_user.return_value = False

        from backend.src.tg_bot.bot import cmd_start
        await cmd_start(mock_message)

        mock_message.answer.assert_called_once()
        args = mock_message.answer.call_args[1]
        assert 'reply_markup' in args
        assert 'Добро пожаловать' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_confirm_tg_success(mock_message):
    """Тест успешного подтверждения Telegram"""
    with patch('backend.src.tg_bot.bot.db') as mock_db:
        mock_user = Mock()
        mock_user.id = 1
        mock_db.get_user_by_telegram_username.return_value = mock_user
        mock_db.is_verified_tg_user.return_value = False

        from backend.src.tg_bot.bot import confirm_tg
        await confirm_tg(mock_message)

        mock_db.verified_tg_user.assert_called_once_with(telegram_chat_id=12345, uuid=1)
        mock_message.answer.assert_called_once()
        assert 'успешно привязан' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_confirm_tg_user_not_found(mock_message):
    """Тест подтверждения Telegram для непривязанного аккаунта"""
    with patch('backend.src.tg_bot.bot.db') as mock_db:
        mock_db.get_user_by_telegram_username.return_value = None

        from backend.src.tg_bot.bot import confirm_tg
        await confirm_tg(mock_message)

        mock_db.verified_tg_user.assert_not_called()
        mock_message.answer.assert_called_once()
        assert 'не привязан' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_my_orders(mock_message):
    """Тест кнопки Мои заказы"""
    from backend.src.tg_bot.bot import my_orders
    await my_orders(mock_message)

    mock_message.answer.assert_called_once()
    assert 'Ваши заказы' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_information(mock_message):
    """Тест кнопки Информация"""
    from backend.src.tg_bot.bot import information
    await information(mock_message)

    mock_message.answer.assert_called_once()
    assert 'Информация о боте' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_help_command(mock_message):
    """Тест кнопки Помощь"""
    from backend.src.tg_bot.bot import help_command
    await help_command(mock_message)

    mock_message.answer.assert_called_once()
    assert 'Помощь' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_other_messages(mock_message):
    """Тест обработки других сообщений"""
    with patch('backend.src.tg_bot.bot.db') as mock_db:
        mock_db.is_verified_tg_user.return_value = False

        from backend.src.tg_bot.bot import other_messages
        await other_messages(mock_message)

        mock_message.answer.assert_called_once()
        assert 'используйте кнопки' in mock_message.answer.call_args[0][0]


@pytest.mark.asyncio
async def test_create_main_keyboard_unverified():
    """Тест создания клавиатуры для неверифицированного пользователя"""
    with patch('backend.src.tg_bot.bot.db') as mock_db:
        mock_db.is_verified_tg_user.return_value = False

        keyboard = await create_main_keyboard("testuser")

        assert keyboard is not None
        # Проверяем, что есть кнопка подтверждения
        buttons = keyboard.keyboard
        assert any('✅ Подтвердить ТГ' in str(btn) for btn in buttons)


@pytest.mark.asyncio
async def test_create_main_keyboard_verified():
    """Тест создания клавиатуры для верифицированного пользователя"""
    with patch('backend.src.tg_bot.bot.db') as mock_db:
        mock_db.is_verified_tg_user.return_value = True

        keyboard = await create_main_keyboard("testuser")

        assert keyboard is not None
        # Проверяем, что нет кнопки подтверждения
        buttons = keyboard.keyboard
        assert not any('✅ Подтвердить ТГ' in str(btn) for btn in buttons)