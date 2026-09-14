import os
from dotenv import load_dotenv

from flask import Flask
from flask_bcrypt import Bcrypt
from flask_cors import CORS

from backend.src.db import Database
from flask_jwt_extended import JWTManager
from itsdangerous import URLSafeTimedSerializer


def create_app():
    load_dotenv()

    app = Flask(__name__)
    app.config['SECRET_KEY'] = os.getenv('SECRET_KEY')
    url = os.getenv('URL')

    CORS(app, resources={
        r"/api/cards/*": {
            "origins": ["http://localhost:3000", "https://cardhub.pw"],
            "methods": ["GET", "POST"],
            "allow_headers": ["Content-Type"]
        },
        r"/api/auth/*": {
            "origins": ["http://localhost:3000", "https://cardhub.pw"],
            "methods": ["GET", "POST"],
            "allow_headers": ["Content-Type", "Authorization", "X-Requested-With"]
        }
    })

    from backend.src.web_backend.app.routes import cards
    from backend.src.web_backend.app.routes import base_user

    app.db = Database()
    app.bcrypt = Bcrypt(app)
    app.jwt = JWTManager(app)
    app.serializer = URLSafeTimedSerializer(app.config['SECRET_KEY'])

    app.register_blueprint(cards.bp)
    app.register_blueprint(base_user.bp)

    return app
