import sys
import os

# Добавляем backend/src в Python path
sys.path.insert(0, os.path.join(os.path.dirname(__file__), 'backend', 'src'))

# Теперь импортируем
from run import app

if __name__ == "__main__":
    app.run()