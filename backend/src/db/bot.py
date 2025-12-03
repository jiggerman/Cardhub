import os
from dotenv import load_dotenv

import logging
from aiogram import Bot, Dispatcher, Router, F
from aiogram.types import Message, ReplyKeyboardMarkup, KeyboardButton, ReplyKeyboardRemove
from aiogram.filters import Command
from aiogram.fsm.state import State, StatesGroup
from aiogram.fsm.context import FSMContext
import asyncio

from backend.src.run import db

load_dotenv()
# Токен бота
BOT_TOKEN = os.getenv("TG_TOKEN")

# Инициализация роутера
router = Router()


class Form(StatesGroup):
    waiting_for_confirmation = State()


# Функция создания клавиатуры
async def create_main_keyboard(telegram_username: str) -> ReplyKeyboardMarkup:
    """
    Создает главную клавиатуру.
    Кнопка "Подтвердить ТГ" показывается только если check_tg_confirmed вернула False.
    """
    buttons = []

    # Проверяем статус подтверждения
    is_confirmed = db.is_verified_tg_user(telegram_username=telegram_username)

    # Добавляем кнопку "Подтвердить ТГ" только если не подтверждено
    if not is_confirmed:
        buttons.append([KeyboardButton(text="✅ Подтвердить ТГ")])

    # Остальные кнопки
    buttons.extend([
        [KeyboardButton(text="📦 Мои заказы")],
        [KeyboardButton(text="ℹ️ Информация")],
        [KeyboardButton(text="🆘 Помощь")]
    ])

    return ReplyKeyboardMarkup(
        keyboard=buttons,
        resize_keyboard=True,
        one_time_keyboard=False,
        input_field_placeholder="Выберите действие"
    )


# Обработчик команды /start
@router.message(Command("start"))
async def cmd_start(message: Message):
    """
    Обработчик команды /start
    """
    username = message.from_user.username

    # Приветственное сообщение
    welcome_text = (
        "👋 Добро пожаловать!\n\n"
        "Я ваш помощник. Вот что я умею:\n"
        "• Помочь с подтверждением аккаунта\n"
        "• Показать ваши заказы\n"
        "• Предоставить информацию\n"
        "• Оказать помощь\n\n"
        "Выберите нужный вариант на клавиатуре ниже:"
    )

    # Создаем клавиатуру
    keyboard = await create_main_keyboard(username)

    # Отправляем сообщение с клавиатурой
    await message.answer(
        text=welcome_text,
        reply_markup=keyboard
    )


# Обработчик кнопки "✅ Подтвердить ТГ"
@router.message(F.text == "✅ Подтвердить ТГ")
async def confirm_tg(message: Message):
    """
    Обработчик нажатия на кнопку подтверждения ТГ
    """
    user_chat_id = message.chat.id

    # Здесь должна быть логика подтверждения
    # Например, отправка кода, проверка данных и т.д.

    confirmation_text = None
    user = db.get_user_by_telegram_username(message.from_user.username)

    if user is None:
        confirmation_text = (
            "❌ Этот Telegram-аккаунт не привязан к аккаунту на сайте"
        )
    else:
        db.verified_tg_user(telegram_chat_id=user_chat_id, uuid=user.id)
        confirmation_text = (
            "✅ Telegram-аккаунт успешно привязан к вашему профилю на сайте"
        )

    keyboard = await create_main_keyboard(message.from_user.username)
    await message.answer(confirmation_text, reply_markup=keyboard)


# Обработчик кнопки "📦 Мои заказы"
@router.message(F.text == "📦 Мои заказы")
async def my_orders(message: Message):
    """
    Обработчик кнопки "Мои заказы"
    """
    orders_text = (
        "📦 Ваши заказы:\n\n"
        "1. Заказ #001 - В обработке\n"
        "2. Заказ #002 - Доставляется\n"
        "3. Заказ #003 - Завершен\n\n"
        "Выберите заказ для деталей."
    )

    await message.answer(orders_text)


# Обработчик кнопки "ℹ️ Информация"
@router.message(F.text == "ℹ️ Информация")
async def information(message: Message):
    """
    Обработчик кнопки "Информация"
    """
    info_text = (
        "ℹ️ Информация о боте:\n\n"
        "• Версия: 1.0\n"
        "• Разработчик: CardHub\n"
        "• Контакты: @Vladiisloveee\n\n"
        "Бот создан для помощи с заказами."
    )

    await message.answer(info_text)


# Обработчик кнопки "🆘 Помощь"
@router.message(F.text == "🆘 Помощь")
async def help_command(message: Message):
    """
    Обработчик кнопки "Помощь"
    """
    help_text = (
        "🆘 Помощь:\n\n"
        "Если у вас возникли проблемы:\n"
        "1. Проверьте подключение к интернету\n"
        "2. Перезапустите бота командой /start\n"
        "3. Свяжитесь с поддержкой: @Ramzevi4\n\n"
        "Частые вопросы:\n"
        "• Q: Как подтвердить ТГ?\n"
        "• A: Нажмите кнопку '✅ Подтвердить ТГ'"
    )

    await message.answer(help_text)


# Обработчик для остальных сообщений
@router.message()
async def other_messages(message: Message):
    """
    Обработчик всех остальных сообщений
    """
    await message.answer(
        "Пожалуйста, используйте кнопки на клавиатуре или команду /start",
        reply_markup=await create_main_keyboard(message.from_user.username)
    )


async def main():
    """
    Основная функция запуска бота
    """
    # Инициализация бота и диспетчера
    bot = Bot(token=BOT_TOKEN)
    dp = Dispatcher()
    dp.include_router(router)

    # Запуск бота
    await dp.start_polling(bot)



# Точка входа
if __name__ == "__main__":
    try:
        asyncio.run(main())
    except KeyboardInterrupt:
        logging.info("Бот остановлен")
