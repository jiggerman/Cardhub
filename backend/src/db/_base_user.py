import logging

from backend.src.db._common import with_cursor
from backend.src.db._classes import User


@with_cursor
def register_new_user(self, cursor, username: str, email: str, password_hash: str) -> bool:
    try:
        cursor.execute(
            "INSERT INTO users (username, email, password_hash) VALUES (%s, %s, %s)",
            (username, email, password_hash)
        )

        return True
    except Exception as e:
        self._conn.rollback()
        print(f"Error in register_new_user err: {e}")
        logging.error(f"Error in register_new_user err: {e}")

    return False


@with_cursor
def get_user(self, cursor, email: str) -> User or None:
    try:
        cursor.execute("SELECT * FROM users WHERE email = %s", (email,))
        user = User(cursor.fetchone())

        return user
    except Exception as e:
        print(f"Error in get_user err: {e}")
        logging.error(f"Error in get_user err: {e}")


@with_cursor
def get_user_by_id(self, cursor, uuid: int) -> User or None:
    try:
        cursor.execute("SELECT * FROM users WHERE id = %s", (uuid,))
        user = User(cursor.fetchone())

        return user
    except Exception as e:
        print(f"Error in get_user err: {e}")
        logging.error(f"Error in get_user err: {e}")


@with_cursor
def update_telegram_username(self, cursor, uuid: int, telegram_username: str):
    try:
        cursor.execute("UPDATE users SET telegram_username = %s WHERE id = %s", (telegram_username, uuid,))
    except Exception as e:
        print(f"Error in update_telegram_username err: {e}")
        logging.error(f"Error in update_telegram_username err: {e}")


@with_cursor
def update_username(self, cursor, uuid: int, username: str):
    try:
        cursor.execute("UPDATE users SET username = %s WHERE id = %s", (username, uuid,))
    except Exception as e:
        print(f"Error in update_telegram_username err: {e}")
        logging.error(f"Error in update_telegram_username err: {e}")