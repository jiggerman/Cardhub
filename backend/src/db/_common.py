from functools import wraps
from typing import Callable


def with_cursor(func: Callable) -> Callable:
    """
    Декоратор для выполнения в контексте курсора
    """

    @wraps(func)
    def wrapper(self, *args, **kwargs):
        with self.cursor() as cursor:
            return func(self, cursor, *args, **kwargs)

    return wrapper
