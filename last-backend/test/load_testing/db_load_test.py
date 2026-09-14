# tests/load_testing/db_load_test.py
import time
import random
import threading
import statistics
from concurrent.futures import ThreadPoolExecutor, as_completed
from datetime import datetime
from typing import List, Dict, Any
import psycopg2
from psycopg2.extras import RealDictCursor
import os
from dotenv import load_dotenv
import logging
from tqdm import tqdm
import matplotlib.pyplot as plt
import numpy as np

load_dotenv()


class DatabaseLoadTester:
    def __init__(self, db_config: Dict[str, str], test_name: str = "Load Test"):
        self.db_config = db_config
        self.test_name = test_name
        self.results = {
            'read_tests': [],
            'write_tests': [],
            'complex_tests': []
        }
        self.connection_pool = []
        self.setup_logging()

    def setup_logging(self):
        logging.basicConfig(
            level=logging.INFO,
            format='%(asctime)s - %(name)s - %(levelname)s - %(message)s'
        )
        self.logger = logging.getLogger(__name__)

    def get_connection(self):
        """Создает новое подключение к БД"""
        try:
            conn = psycopg2.connect(
                host=os.getenv('PGHOST'),
                database=os.getenv('PGDATABASE'),
                user=os.getenv('PGUSER'),
                password=os.getenv('PGPASSWORD'),
                port=os.getenv('DB_PORT', '5432'),
                cursor_factory=RealDictCursor
            )
            return conn
        except Exception as e:
            self.logger.error(f"Connection error: {e}")
            return None

    def initialize_pool(self, pool_size: int = 10):
        """Инициализирует пул соединений"""
        self.logger.info(f"Initializing connection pool with {pool_size} connections")
        with ThreadPoolExecutor(max_workers=pool_size) as executor:
            futures = [executor.submit(self.get_connection) for _ in range(pool_size)]
            for future in as_completed(futures):
                conn = future.result()
                if conn:
                    self.connection_pool.append(conn)
        self.logger.info(f"Pool initialized with {len(self.connection_pool)} connections")

    def close_pool(self):
        """Закрывает все соединения в пуле"""
        for conn in self.connection_pool:
            try:
                conn.close()
            except:
                pass
        self.connection_pool.clear()

    # ----- ТЕСТОВЫЕ СЦЕНАРИИ -----

    def test_simple_read(self, conn, query_param: str = None):
        """Простой тест чтения - поиск карт по имени"""
        try:
            start_time = time.time()
            with conn.cursor() as cursor:
                if query_param:
                    cursor.execute(
                        "SELECT * FROM cards WHERE name ILIKE %s LIMIT 100",
                        (f"%{query_param}%",)
                    )
                else:
                    cursor.execute("SELECT * FROM cards LIMIT 100")
                results = cursor.fetchall()
            end_time = time.time()
            return {
                'success': True,
                'duration': end_time - start_time,
                'rows_returned': len(results)
            }
        except Exception as e:
            return {
                'success': False,
                'duration': time.time() - start_time,
                'error': str(e)
            }

    def test_complex_read(self, conn, card_name: str = None):
        """Сложный тест чтения - поиск с JOIN"""
        try:
            start_time = time.time()
            with conn.cursor() as cursor:
                query = """
                SELECT 
                    c.id,
                    c.name,
                    c.set_name,
                    COUNT(ci.id) as inventory_count,
                    COALESCE(AVG(ci.price), 0) as avg_price,
                    COALESCE(MIN(ci.price), 0) as min_price,
                    COALESCE(MAX(ci.price), 0) as max_price
                FROM cards c
                LEFT JOIN card_inventory ci ON c.id = ci.card_id
                WHERE c.name ILIKE %s
                GROUP BY c.id
                ORDER BY c.name
                LIMIT 50
                """
                cursor.execute(query, (f"%{card_name or 'a'}%",))
                results = cursor.fetchall()
            end_time = time.time()
            return {
                'success': True,
                'duration': end_time - start_time,
                'rows_returned': len(results)
            }
        except Exception as e:
            return {
                'success': False,
                'duration': time.time() - start_time,
                'error': str(e)
            }

    def test_write_operation(self, conn):
        """Тест записи - добавление записи в инвентарь"""
        try:
            start_time = time.time()
            with conn.cursor() as cursor:
                # Получаем случайную карту
                cursor.execute("SELECT id FROM cards ORDER BY RANDOM() LIMIT 1")
                card = cursor.fetchone()

                if card:
                    cursor.execute("""
                        INSERT INTO card_inventory 
                        (card_id, lang, quality, foil, quantity, price, owner_id)
                        VALUES (%s, %s, %s, %s, %s, %s, %s)
                        RETURNING id
                    """, (
                        card['id'],
                        random.choice(['en', 'ru', 'jp']),
                        random.choice(['NM', 'SP', 'MP', 'HP']),
                        random.choice([True, False]),
                        random.randint(1, 10),
                        round(random.uniform(0.5, 100.0), 2),
                        1  # тестовый user_id
                    ))
                    new_id = cursor.fetchone()
                    conn.commit()

            end_time = time.time()
            return {
                'success': True,
                'duration': end_time - start_time,
                'inserted_id': new_id['id'] if new_id else None
            }
        except Exception as e:
            conn.rollback()
            return {
                'success': False,
                'duration': time.time() - start_time,
                'error': str(e)
            }

    def test_update_operation(self, conn):
        """Тест обновления данных"""
        try:
            start_time = time.time()
            with conn.cursor() as cursor:
                cursor.execute("""
                    UPDATE card_inventory 
                    SET quantity = quantity + 1,
                        updated_at = CURRENT_TIMESTAMP
                    WHERE id IN (
                        SELECT id FROM card_inventory 
                        ORDER BY RANDOM() 
                        LIMIT 10
                    )
                    RETURNING id
                """)
                updated = cursor.fetchall()
                conn.commit()

            end_time = time.time()
            return {
                'success': True,
                'duration': end_time - start_time,
                'rows_updated': len(updated)
            }
        except Exception as e:
            conn.rollback()
            return {
                'success': False,
                'duration': time.time() - start_time,
                'error': str(e)
            }

    def test_transaction_isolation(self, conn):
        """Тест изоляции транзакций"""
        try:
            start_time = time.time()
            with conn.cursor() as cursor:
                # Начинаем транзакцию
                cursor.execute("BEGIN")

                # Читаем текущее значение
                cursor.execute("SELECT COUNT(*) as count FROM card_inventory")
                before_count = cursor.fetchone()['count']

                # Обновляем данные
                cursor.execute("""
                    UPDATE card_inventory 
                    SET quantity = quantity + 1 
                    WHERE id IN (SELECT id FROM card_inventory LIMIT 5)
                """)

                # Проверяем в рамках транзакции
                cursor.execute("SELECT COUNT(*) as count FROM card_inventory")
                during_count = cursor.fetchone()['count']

                # Откатываем
                cursor.execute("ROLLBACK")

                # Проверяем после отката
                cursor.execute("SELECT COUNT(*) as count FROM card_inventory")
                after_count = cursor.fetchone()['count']

            end_time = time.time()
            return {
                'success': True,
                'duration': end_time - start_time,
                'before_count': before_count,
                'during_count': during_count,
                'after_count': after_count
            }
        except Exception as e:
            return {
                'success': False,
                'duration': time.time() - start_time,
                'error': str(e)
            }

    # ----- ЗАПУСК ТЕСТОВ -----

    def run_concurrent_test(self, test_func, num_threads: int, iterations_per_thread: int,
                            test_type: str, **kwargs):
        """Запускает конкурентный тест"""
        self.logger.info(f"Running {test_type} test with {num_threads} threads, "
                         f"{iterations_per_thread} iterations each")

        results = []

        def worker(thread_id):
            thread_results = []
            # Используем соединение из пула
            conn = self.connection_pool[thread_id % len(self.connection_pool)]

            for i in range(iterations_per_thread):
                # Параметры для теста
                test_params = kwargs.copy()
                if 'card_name' in kwargs and kwargs['card_name'] is None:
                    test_params['card_name'] = random.choice(['a', 'e', 'i', 'o', 'u'])
                if 'query_param' in kwargs and kwargs['query_param'] is None:
                    test_params['query_param'] = random.choice(['a', 'b', 'c'])

                result = test_func(conn, **test_params)
                result['thread_id'] = thread_id
                result['iteration'] = i
                thread_results.append(result)

                # Небольшая задержка для реалистичности
                time.sleep(random.uniform(0.001, 0.01))

            return thread_results

        with ThreadPoolExecutor(max_workers=num_threads) as executor:
            futures = [executor.submit(worker, i) for i in range(num_threads)]

            for future in tqdm(as_completed(futures), total=num_threads,
                               desc=f"Running {test_type} tests"):
                thread_results = future.result()
                results.extend(thread_results)

        # Анализируем результаты
        analysis = self.analyze_results(results, test_type)
        self.results[test_type].append({
            'test_name': test_func.__name__,
            'num_threads': num_threads,
            'iterations_per_thread': iterations_per_thread,
            'total_operations': len(results),
            'analysis': analysis,
            'raw_results': results
        })

        return analysis

    def analyze_results(self, results: List[Dict], test_type: str) -> Dict:
        """Анализирует результаты тестов"""
        successful = [r for r in results if r['success']]
        failed = [r for r in results if not r['success']]

        if not successful:
            return {
                'success_rate': 0,
                'avg_duration': 0,
                'min_duration': 0,
                'max_duration': 0,
                'p95_duration': 0,
                'p99_duration': 0,
                'throughput': 0,
                'failed_count': len(failed)
            }

        durations = [r['duration'] for r in successful]

        return {
            'success_rate': len(successful) / len(results) * 100,
            'avg_duration': statistics.mean(durations),
            'min_duration': min(durations),
            'max_duration': max(durations),
            'p95_duration': np.percentile(durations, 95),
            'p99_duration': np.percentile(durations, 99),
            'throughput': len(successful) / sum(durations) if sum(durations) > 0 else 0,
            'failed_count': len(failed)
        }

    def run_full_test_suite(self, thread_counts: List[int] = [1, 5, 10, 20, 50],
                            iterations_per_thread: int = 100):
        """Запускает полный набор тестов"""
        self.logger.info("=" * 60)
        self.logger.info(f"Starting full test suite: {self.test_name}")
        self.logger.info("=" * 60)

        # Инициализируем пул соединений
        self.initialize_pool(pool_size=max(thread_counts))

        report = {
            'test_name': self.test_name,
            'timestamp': datetime.now().isoformat(),
            'thread_counts_tested': thread_counts,
            'iterations_per_thread': iterations_per_thread,
            'results': {}
        }

        for num_threads in thread_counts:
            self.logger.info(f"\n--- Testing with {num_threads} concurrent threads ---")

            # Тесты чтения
            simple_read = self.run_concurrent_test(
                self.test_simple_read, num_threads, iterations_per_thread,
                'read_tests', query_param=None
            )

            complex_read = self.run_concurrent_test(
                self.test_complex_read, num_threads, iterations_per_thread,
                'read_tests', card_name=None
            )

            # Тесты записи
            write_test = self.run_concurrent_test(
                self.test_write_operation, num_threads, iterations_per_thread // 5,
                'write_tests'
            )

            update_test = self.run_concurrent_test(
                self.test_update_operation, num_threads, iterations_per_thread // 5,
                'write_tests'
            )

            # Тест транзакций
            transaction_test = self.run_concurrent_test(
                self.test_transaction_isolation, num_threads, iterations_per_thread // 10,
                'complex_tests'
            )

            report['results'][num_threads] = {
                'simple_read': simple_read,
                'complex_read': complex_read,
                'write_test': write_test,
                'update_test': update_test,
                'transaction_test': transaction_test
            }

        self.close_pool()
        self.generate_report(report)
        return report

    def generate_report(self, report: Dict):
        """Генерирует отчет с графиками"""
        self.logger.info("\n" + "=" * 60)
        self.logger.info("LOAD TEST REPORT")
        self.logger.info("=" * 60)
        self.logger.info(f"Test: {report['test_name']}")
        self.logger.info(f"Timestamp: {report['timestamp']}")
        self.logger.info(f"Iterations per thread: {report['iterations_per_thread']}")
        self.logger.info("-" * 60)

        # Создаем графики
        fig, axes = plt.subplots(2, 2, figsize=(15, 10))
        fig.suptitle(f'Database Load Test Results - {report["test_name"]}')

        thread_counts = list(report['results'].keys())

        # График 1: Среднее время ответа
        ax1 = axes[0, 0]
        for test_type in ['simple_read', 'complex_read', 'write_test']:
            avg_durations = [
                report['results'][tc][test_type]['avg_duration'] * 1000  # в миллисекундах
                for tc in thread_counts
            ]
            ax1.plot(thread_counts, avg_durations, marker='o', label=test_type)
        ax1.set_xlabel('Number of Threads')
        ax1.set_ylabel('Avg Response Time (ms)')
        ax1.set_title('Average Response Time')
        ax1.legend()
        ax1.grid(True)

        # График 2: Пропускная способность
        ax2 = axes[0, 1]
        for test_type in ['simple_read', 'complex_read', 'write_test']:
            throughput = [
                report['results'][tc][test_type]['throughput']
                for tc in thread_counts
            ]
            ax2.plot(thread_counts, throughput, marker='s', label=test_type)
        ax2.set_xlabel('Number of Threads')
        ax2.set_ylabel('Throughput (ops/sec)')
        ax2.set_title('Throughput')
        ax2.legend()
        ax2.grid(True)

        # График 3: Процент успешных операций
        ax3 = axes[1, 0]
        for test_type in ['simple_read', 'complex_read', 'write_test']:
            success_rates = [
                report['results'][tc][test_type]['success_rate']
                for tc in thread_counts
            ]
            ax3.plot(thread_counts, success_rates, marker='^', label=test_type)
        ax3.set_xlabel('Number of Threads')
        ax3.set_ylabel('Success Rate (%)')
        ax3.set_title('Success Rate')
        ax3.legend()
        ax3.grid(True)

        # График 4: P95 время ответа
        ax4 = axes[1, 1]
        for test_type in ['simple_read', 'complex_read', 'write_test']:
            p95_times = [
                report['results'][tc][test_type]['p95_duration'] * 1000
                for tc in thread_counts
            ]
            ax4.plot(thread_counts, p95_times, marker='d', label=test_type)
        ax4.set_xlabel('Number of Threads')
        ax4.set_ylabel('P95 Response Time (ms)')
        ax4.set_title('95th Percentile Response Time')
        ax4.legend()
        ax4.grid(True)

        plt.tight_layout()
        plt.savefig(f'load_test_report_{datetime.now().strftime("%Y%m%d_%H%M%S")}.png')
        plt.show()

        # Выводим текстовый отчет
        self.print_text_report(report)

    def print_text_report(self, report: Dict):
        """Выводит текстовый отчет"""
        for thread_count, results in report['results'].items():
            self.logger.info(f"\n--- Thread count: {thread_count} ---")

            for test_name, metrics in results.items():
                self.logger.info(f"  {test_name}:")
                self.logger.info(f"    Success Rate: {metrics['success_rate']:.2f}%")
                self.logger.info(f"    Avg Time: {metrics['avg_duration'] * 1000:.2f} ms")
                self.logger.info(f"    P95 Time: {metrics['p95_duration'] * 1000:.2f} ms")
                self.logger.info(f"    Throughput: {metrics['throughput']:.2f} ops/sec")
                if metrics['failed_count'] > 0:
                    self.logger.info(f"    Failed: {metrics['failed_count']}")


# ----- ТЕСТЫ С ЗАПОЛНЕНИЕМ БОЛЬШИХ ДАННЫХ -----

class DataGenerator:
    """Генератор тестовых данных"""

    @staticmethod
    def generate_test_users(count: int) -> List[Dict]:
        users = []
        for i in range(count):
            users.append({
                'email': f'test_user_{i}@example.com',
                'username': f'testuser{i}',
                'password_hash': f'hash_{i}',
                'role': random.choice(['user', 'user', 'user', 'admin']),
                'telegram_username': f'@tg_test_{i}'
            })
        return users

    @staticmethod
    def generate_test_cards(db_conn, count: int):
        """Генерирует тестовые карты"""
        colors = ['White', 'Blue', 'Black', 'Red', 'Green', 'Multicolor', 'Colorless']
        sets = ['MH3', 'MKM', 'LCI', 'WOE', 'MOM']
        types = ['Creature', 'Instant', 'Sorcery', 'Enchantment', 'Artifact', 'Planeswalker']

        with db_conn.cursor() as cursor:
            for i in range(count):
                cursor.execute("""
                    INSERT INTO cards 
                    (color, set_code, set_name, collector_number, name, card_type,
                     image_url_small, image_url_normal, image_url_large)
                    VALUES (%s, %s, %s, %s, %s, %s, %s, %s, %s)
                """, (
                    random.choice(colors),
                    random.choice(sets),
                    f"Test Set {i}",
                    str(i),
                    f"Test Card {i}",
                    random.choice(types),
                    f"http://test.com/small_{i}.jpg",
                    f"http://test.com/normal_{i}.jpg",
                    f"http://test.com/large_{i}.jpg"
                ))
            db_conn.commit()


if __name__ == "__main__":
    # Конфигурация для тестов
    db_config = {
        'host': os.getenv('PGHOST', 'localhost'),
        'database': os.getenv('PGDATABASE', 'cardhub_test'),
        'user': os.getenv('PGUSER', 'postgres'),
        'password': os.getenv('PGPASSWORD', ''),
        'port': os.getenv('DB_PORT', '5432')
    }

    # Создаем тестовую БД если нужно
    # ...

    # Запускаем нагрузочное тестирование
    tester = DatabaseLoadTester(db_config, "CardHub Database Load Test")

    # Быстрый тест
    # report = tester.run_full_test_suite(
    #     thread_counts=[1, 5, 10],
    #     iterations_per_thread=50
    # )

    # Полный тест
    report = tester.run_full_test_suite(
        thread_counts=[1, 5, 10, 20, 50, 100],
        iterations_per_thread=200
    )