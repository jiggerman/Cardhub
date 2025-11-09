import json
import logging

from tqdm import tqdm

from backend.src.db._common import with_cursor


@with_cursor
def add_cards_from_file(self, cursor, file_path: str = 'Cardhub/default-cards.json'):
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
        print(f"Error in parse/open file with default-cards.json. error: {e}")
        logging.error(f"Error in parse/open file with default-cards.json. error: {e}")


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


@with_cursor
def search_card(self, cursor, card_name) -> tuple:
    cursor.execute("""SELECT * FROM cards WHERE name ILIKE %s;""", (f"%{card_name}%",))
    cards = cursor.fetchall()

    return len(cards), cards


@with_cursor
def search_cards_with_inventory(self, cursor, card_name):
    query = """
    SELECT 
        c.id,
        c.color,
        c.set_code,
        c.set_name, 
        c.collector_number,
        c.name,
        c.card_type,
        c.image_url_small,
        c.image_url_normal,
        c.image_url_large,
        c.created_at,
        c.updated_at,
        COALESCE(SUM(ci.quantity), 0) as total_quantity,
        MIN(CASE WHEN ci.quantity > 0 THEN ci.price END) as min_price,
        ARRAY_AGG(DISTINCT ci.quality) FILTER (WHERE ci.quantity > 0) as available_qualities
    FROM cards c
    LEFT JOIN card_inventory ci ON c.id = ci.card_id 
        AND ci.quantity > 0 
        AND ci.quality IN ('NM', 'SP', 'HP', 'MP', 'DM')
    WHERE c.name ILIKE %s
    GROUP BY c.id
    ORDER BY c.name, c.set_name
    """
    cursor.execute(query, (f"%{card_name}%",))
    cards = cursor.fetchall()

    return len(cards), cards
