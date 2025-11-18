import os
import sys
import logging

from flask import Blueprint, jsonify, request, current_app
from flask_jwt_extended import JWTManager, create_access_token, jwt_required, get_jwt_identity, create_refresh_token
from flask_bcrypt import Bcrypt

from backend.src.db import Database


bp = Blueprint('base_user', __name__)


@bp.route('/auth/register', methods=['POST'])
def register_new_user():
    try:
        data = request.get_json()

        db: Database = current_app.db
        bcrypt: Bcrypt = current_app.bcrypt

        username = data.get('username')
        email = data.get('email').lower()
        password = data.get('password')

        if db.get_user(email) is not None:
            return jsonify({'error': 'Данный email уже зарегистрирован'}), 400

        password_hash = bcrypt.generate_password_hash(password).decode('utf-8')
        db.register_new_user(username=username, email=email, password_hash=password_hash)

        return jsonify({'message': 'Пользователь успешно создан'}), 201
    except Exception as e:
        return jsonify({'error': str(e)}), 500


@bp.route('/auth/login', methods=['POST'])
def login():
    try:
        db: Database = current_app.db
        bcrypt: Bcrypt = current_app.bcrypt

        data = request.get_json()
        email = data.get('email').lower()
        password = data.get('password')

        if email is None or password is None:
            return jsonify({'message': 'Не все поля заполнены'}), 400

        user = db.get_user(email=email)

        if not user:
            return jsonify({'message': 'Пользователь не найден'}), 404

        if not bcrypt.check_password_hash(user.password_hash, password):
            return jsonify({'message': 'Неверный пароль'}), 401

        #if not user.email_verified:
        #    return jsonify({'message': 'Пожалуйста, подтвердите свой адрес электронной почты перед входом в систему.'}), 403

        access_token = create_access_token(identity=str(user.id))
        refresh_token = create_refresh_token(identity=str(user.id))
        return jsonify(access_token=access_token, refresh_token=refresh_token), 200
    except Exception as err:
        logging.error(f"Ошибка: {err}\n")
        return jsonify({'message': 'Внутренняя ошибка сервера'}), 500


@bp.route('/auth/user', methods=['GET'])
def get_user():
    try:
        # Проверяем JWT
        from flask_jwt_extended import verify_jwt_in_request
        try:
            verify_jwt_in_request()
            current_user_id = get_jwt_identity()
        except Exception as jwt_err:
            return jsonify({'message': 'JWT Error: ' + str(jwt_err)}), 401

        db: Database = current_app.db
        user = db.get_user_by_id(uuid=int(current_user_id)).data
        print(user)
        return jsonify(user=user), 200
    except Exception as err:
        logging.error(f"Ошибка: {err}\n")
        return jsonify({'message': 'Внутренняя ошибка сервера'}), 500