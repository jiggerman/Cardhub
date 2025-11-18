import json
import logging

from backend.src.db._common import with_cursor


class User:
    def __init__(self, data):
        self.id, self.email, self.password_hash, self.username, self.role, self.email_verified, \
            self.email_verification_token, self.telegram_chat_id, self.telegram_url, self.shipping_address, \
            self.created_at, self.updated_at = data
        self.data = [dat for i, dat in enumerate(data) if i != 2]

    def __str__(self):
        return f"{self.data}"


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
