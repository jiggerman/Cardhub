import logging

from backend.src.db._common import with_cursor
from backend.src.db._classes import User


@with_cursor
def get_user_by_telegram_username(self, cursor, telegram_username: int) -> User | None:
    try:
        cursor.execute("SELECT * FROM users WHERE telegram_username = %s", (telegram_username, ))
        user = cursor.fetchone()

        if user is not None:
            return User(user)

        return None
    except Exception as e:
        logging.error(f"Ошибка верификации телеграмма пользователя: {e}")


@with_cursor
def is_verified_tg_user(self, cursor, telegram_username: int) -> bool:
    try:
        cursor.execute("SELECT * FROM users WHERE telegram_username = %s", (telegram_username, ))
        user = cursor.fetchone()

        if user is not None:
            return User(user).telegram_verified
        return False
    except Exception as e:
        logging.error(f"Ошибка верификации телеграмма пользователя: {e}")


@with_cursor
def verified_tg_user(self, cursor, telegram_chat_id, uuid: int):
    try:
        cursor.execute("UPDATE users SET telegram_verified = TRUE, telegram_chat_id = %s WHERE id = %s",
                               (telegram_chat_id, uuid,))
    except Exception as e:
        logging.error(f"Ошибка верификации телеграмма пользователя: {e}")


