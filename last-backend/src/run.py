from backend.src.web_backend.app import create_app
from backend.src.db import Database

app = create_app()
db = Database()

if __name__ == '__main__':
    app.run(debug=True, host='0.0.0.0', port=5000)
