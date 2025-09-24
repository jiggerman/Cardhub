import os
import logging
from dotenv import load_dotenv

import psycopg2
from psycopg2 import sql


load_dotenv()

class Database:
    def __init__(self):
        self.conn = None
        self.connect()

    def connect(self):
        try:
            self.conn = psycopg2.connect(
                host=os.getenv('DB_HOST', 'localhost'),
                database=os.getenv('DB_NAME', 'mtg_store'),
                user=os.getenv('DB_USER', 'postgres'),
                password=os.getenv('DB_PASSWORD', ''),
                port=os.getenv('DB_PORT', '5432')
            )
            print("Connected to PostgreSQL successfully")
            logging.info("Connected to PostgreSQL successfully")
        except Exception as e:
            print(f"Connection error: {e}")
            logging.error(f"Connection error: {e}")
