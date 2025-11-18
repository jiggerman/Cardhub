import os
import logging
from dotenv import load_dotenv

import psycopg2

from contextlib import contextmanager
from typing import Iterator, Optional

from backend.src.db._queries import TABLE_CREATE

from backend.src.db._common import with_cursor

load_dotenv()


class Database:
    def __init__(self):
        self._conn: Optional[psycopg2.extensions.connection] = None

    @property
    def conn(self) -> psycopg2.extensions.connection:
        """
        Подключение к базе данных
        :return: psycopg2.extensions.connection
        """
        try:
            if self._conn is None or self._conn.closed:
                self._conn = psycopg2.connect(
                    host=os.getenv('PGHOST'),
                    database=os.getenv('PGDATABASE'),
                    user=os.getenv('PGUSER'),
                    password=os.getenv('PGPASSWORD'),
                    port=os.getenv('DB_PORT')
                )
                print("Connected to PostgreSQL successfully")
                logging.info("Connected to PostgreSQL successfully")

            return self._conn
        except Exception as e:
            print(f"Connection error: {e}")
            logging.error(f"Connection error: {e}")

    def __enter__(self):
        """
        Вход в контекст
        :return: объект класса
        """
        return self

    def __exit__(self, exc_type, exc_val, exc_tb):
        """
        Выход из контекста
        :param exc_type: тип ошибки
        """
        if self._conn and not self._conn.closed:
            if exc_type is None:
                self._conn.commit()
            else:
                self._conn.rollback()
            self._conn.close()

    @contextmanager
    def cursor(self) -> Iterator[psycopg2.extensions.cursor]:
        """
        Контекст для менеджера курсора
        :yield: курсор
        """
        with self.conn.cursor() as cursor:
            try:
                yield cursor
                self._conn.commit()
            except Exception:
                self.conn.rollback()
                raise
            finally:
                cursor.close()

    @with_cursor
    def create_tables(self, cursor):
        """
        Создание таблиц базы данных
        """
        try:
            for table, query in TABLE_CREATE.items():
                cursor.execute(query)
            print("Create tables successfully")
            logging.info("Create tables successfully")
        except Exception as e:
            print(f"Create tables error: {e}")
            logging.error(f"Create tables error: {e}")

    @with_cursor
    def set_indexs(self, cursor):
        try:
            self._conn.autocommit = True
            cursor.execute("CREATE EXTENSION IF NOT EXISTS pg_trgm;")

            transactions = [
                "CREATE INDEX CONCURRENTLY idx_cards_name_gin_trgm ON cards USING gin (name gin_trgm_ops);",
                "CREATE INDEX CONCURRENTLY idx_cards_set_code ON cards(set_code);",
                "CREATE INDEX CONCURRENTLY idx_cards_card_type ON cards(card_type);",
                "CREATE INDEX CONCURRENTLY idx_cards_color ON cards(color);"
            ]

            for tran in transactions:
                cursor.execute(tran)

        except Exception as e:
            print(f"Error in set indexses error: {e}")
            logging.error(f"Error in set indexses error: {e}")
            self._conn.rollback()
        finally:
            self._conn.autocommit = False

    """ ---- Cards ---- """
    from backend.src.db._cards import add_cards_from_file, transform_card_data, search_card, search_cards_with_inventory

    """ ---- Base_user  ---- """
    from backend.src.db._base_user import register_new_user, get_user, get_user_by_id


if __name__ == '__main__':
    db = Database()
    db.create_tables()
    print(db.get_user(email='kurva@mail.ru'))
