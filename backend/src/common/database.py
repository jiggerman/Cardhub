import os
import logging
from dotenv import load_dotenv

import psycopg2
from psycopg2 import sql

from functools import wraps
from contextlib import contextmanager
from typing import Any, Callable, Iterator, Optional

from queries import TABLE_CREATE

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

    def with_cursor(func: Callable) -> Callable:
        """
        Декоратор для выполнения в контексте курсора
        """
        @wraps(func)
        def wrapper(self, *args, **kwargs):
            with self.cursor() as cursor:
                return func(self, cursor, *args, **kwargs)

        return wrapper

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