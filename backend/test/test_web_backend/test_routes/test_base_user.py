import pytest
import json
from unittest.mock import Mock, patch
from flask import Flask
from flask_jwt_extended import create_access_token


class TestBaseUserRoutes:
    def test_register_new_user_success(self, client, app):
        """Тест успешной регистрации"""
        with app.app_context():
            app.db.get_user.return_value = None
            app.db.register_new_user.return_value = True

            response = client.post('/api/auth/register',
                                   json={
                                       'username': 'testuser',
                                       'email': 'test@example.com',
                                       'password': 'password123'
                                   })

            assert response.status_code == 201
            assert response.json['message'] == 'Пользователь успешно создан'
            app.db.register_new_user.assert_called_once()

    def test_register_new_user_email_exists(self, client, app, sample_user_data):
        """Тест регистрации с существующим email"""
        with app.app_context():
            from backend.src.db._classes import User
            app.db.get_user.return_value = User(tuple(sample_user_data.values()))

            response = client.post('/api/auth/register',
                                   json={
                                       'username': 'testuser',
                                       'email': 'test@example.com',
                                       'password': 'password123'
                                   })

            assert response.status_code == 400
            assert response.json['error'] == 'Данный email уже зарегистрирован'

    def test_login_success(self, client, app, sample_user_data):
        """Тест успешного логина"""
        with app.app_context():
            from backend.src.db._classes import User
            app.bcrypt = Mock()
            app.bcrypt.check_password_hash.return_value = True

            user = User(tuple(sample_user_data.values()))
            app.db.get_user.return_value = user

            response = client.post('/api/auth/login',
                                   json={
                                       'email': 'test@example.com',
                                       'password': 'password123'
                                   })

            assert response.status_code == 200
            assert 'access_token' in response.json
            assert 'refresh_token' in response.json

    def test_login_user_not_found(self, client, app):
        """Тест логина с несуществующим пользователем"""
        with app.app_context():
            app.db.get_user.return_value = None

            response = client.post('/api/auth/login',
                                   json={
                                       'email': 'notfound@example.com',
                                       'password': 'password123'
                                   })

            assert response.status_code == 404
            assert response.json['message'] == 'Пользователь не найден'

    def test_login_wrong_password(self, client, app, sample_user_data):
        """Тест логина с неверным паролем"""
        with app.app_context():
            from backend.src.db._classes import User
            app.bcrypt = Mock()
            app.bcrypt.check_password_hash.return_value = False

            user = User(tuple(sample_user_data.values()))
            app.db.get_user.return_value = user

            response = client.post('/api/auth/login',
                                   json={
                                       'email': 'test@example.com',
                                       'password': 'wrongpassword'
                                   })

            assert response.status_code == 401
            assert response.json['message'] == 'Неверный пароль'

    def test_get_user_success(self, client, app, sample_user_data):
        """Тест получения данных пользователя"""
        with app.app_context():
            from backend.src.db._classes import User
            from flask_jwt_extended import create_access_token

            access_token = create_access_token(identity='1')
            user = User(tuple(sample_user_data.values()))
            app.db.get_user_by_id.return_value = user

            response = client.get('/api/auth/user',
                                  headers={'Authorization': f'Bearer {access_token}'})

            assert response.status_code == 200
            assert 'user' in response.json

    def test_update_user_profile(self, client, app):
        """Тест обновления профиля пользователя"""
        with app.app_context():
            from flask_jwt_extended import create_access_token

            access_token = create_access_token(identity='1')

            response = client.post('/api/auth/user_update_profile',
                                   headers={'Authorization': f'Bearer {access_token}'},
                                   json={
                                       'username': 'newusername',
                                       'telegram_username': '@newtelegram'
                                   })

            assert response.status_code == 200
            assert response.json['message'] == 'Изменения сохранены'
            app.db.update_username.assert_called_once_with(uuid='1', username='newusername')
            app.db.update_telegram_username.assert_called_once_with(uuid='1', telegram_username='@newtelegram')