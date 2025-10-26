import os
import logging
from dotenv import load_dotenv

import json
from tqdm import tqdm

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

    @with_cursor
    def add_cards_from_file(self, cursor, file_path: str='../../../default-cards.json'):
        try:
            with open(file_path, 'r', encoding='UTF-8') as file:
                cards = json.load(file)
                for card in tqdm(cards):
                    card_data = tuple(self.transform_card_data(card).values())
                    try:
                        cursor.execute("""INSERT INTO cards (color, set_code, set_name, collector_number, name, 
                            card_type, image_url_small, image_url_normal, image_url_large) VALUES
                            (%s, %s, %s, %s, %s, %s, %s, %s, %s)""", card_data)
                    except Exception as e:
                        self._conn.rollback()
                        logging.error(f"Can't add card: {card_data} Error: {e}")
        except Exception as e:
            a(f"Error in parse/open file with default-cards.json. error: {e}")
            logging.error(f"Error in parse/open file with default-cards.json. error: {e}")

    @classmethod
    def transform_card_data(self, card_data):
        """Преобразует данные карты из Scryfall в формат для БД"""
        # Определяем цвет на основе colors
        color_identity = card_data.get('color_identity', [])
        card_type = card_data.get('type_line', '')

        if len(color_identity) == 0:
            color = 'Colorless'
        elif len(color_identity) > 1:
            color = 'Multicolor'
        else:
            color_map = {'W': 'White', 'U': 'Blue', 'B': 'Black', 'R': 'Red', 'G': 'Green'}
            color = color_map.get(color_identity[0], 'Unknown')

        # Получаем URL изображений
        image_uris = card_data.get('image_uris', {})

        return {
            'color': color,
            'set_code': card_data.get('set', ''),
            'set_name': card_data.get('set_name', ''),
            'collector_number': str(card_data.get('collector_number', 0)),
            'name': card_data.get('name', ''),
            'card_type': card_type,
            'image_url_small': image_uris.get('small', ''),
            'image_url_normal': image_uris.get('normal', ''),
            'image_url_large': image_uris.get('large', '')
        }


db = Database()
db.set_indexs()