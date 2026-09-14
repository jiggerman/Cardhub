import json
import logging
from pathlib import Path
from django.core.management.base import BaseCommand
from django.db import transaction
from tqdm import tqdm
from cards.models import Card

logger = logging.getLogger(__name__)

class Command(BaseCommand):
    help = 'Импорт карт из JSON (Scryfall) в базу данных'

    def add_arguments(self, parser):
        parser.add_argument('file_path', type=str, help='Путь к JSON файлу')
        parser.add_argument('--batch-size', type=int, default=1000, help='Размер пакета для bulk_create')

    def handle(self, *args, **options):
        file_path = Path(options['file_path'])
        batch_size = options['batch_size']

        if not file_path.exists():
            self.stderr.write(self.style.ERROR(f'Файл не найден: {file_path}'))
            return

        self.stdout.write(f' Читаем {file_path}...')
        with open(file_path, 'r', encoding='utf-8') as f:
            cards_data = json.load(f)

        self.stdout.write(f'Найдено {len(cards_data)} записей.')

        batch = []
        created_count = 0
        skipped_count = 0

        for card_json in tqdm(cards_data, desc='Обработка карт', unit='карта'):
            try:
                card_obj = self._transform_card_data(card_json)
                batch.append(card_obj)

                if len(batch) >= batch_size:
                    c, s = self._save_batch(batch)
                    created_count += c
                    skipped_count += s
                    batch.clear()
            except Exception as e:
                logger.error(f"Ошибка обработки карты {card_json.get('name', 'Unknown')}: {e}")
                skipped_count += 1

        # Сохраняем остаток
        if batch:
            c, s = self._save_batch(batch)
            created_count += c
            skipped_count += s

        self.stdout.write(self.style.SUCCESS(
            f'\nИмпорт завершён\n'
            f'Добавлено: {created_count}\n'
            f'Пропущено/Ошибки: {skipped_count}'
        ))

    def _transform_card_data(self, card_data: dict) -> Card:
        color_identity = card_data.get('color_identity', [])
        if not color_identity:
            color = 'Colorless'
        elif len(color_identity) > 1:
            color = 'Multicolor'
        else:
            color_map = {'W': 'White', 'U': 'Blue', 'B': 'Black', 'R': 'Red', 'G': 'Green'}
            color = color_map.get(color_identity[0], 'Unknown')

        image_uris = card_data.get('image_uris', {})

        return Card(
            color=color,
            set_code=card_data.get('set', ''),
            set_name=card_data.get('set_name', ''),
            collection_number=str(card_data.get('collector_number', '')),
            name=card_data.get('name', ''),
            card_type=card_data.get('type_line', ''),
            image_url_small=image_uris.get('small', ''),
            image_url_normal=image_uris.get('normal', ''),
            image_url_large=image_uris.get('large', ''),
        )

    def _save_batch(self, batch: list) -> tuple[int, int]:
        try:
            Card.objects.bulk_create(batch, ignore_conflicts=True)
            return len(batch), 0
        except Exception as e:
            logger.error(f"Ошибка пакетной вставки: {e}")
            return 0, len(batch)