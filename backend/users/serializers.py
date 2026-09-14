from rest_framework import serializers
from django.contrib.auth import get_user_model
from django.contrib.auth.password_validation import validate_password


User = get_user_model()


class RegisterUserSerializer(serializers.ModelSerializer):
    password = serializers.CharField(write_only=True, required=True, validators=[validate_password])
    password2 = serializers.CharField(write_only=True, required=True)

    class Meta:
        model = User
        fields = ('email', 'username', 'password', 'password2')

    def validate_email(self, value):
        if User.objects.filter(email=value).exists():
            raise serializers.ValidationError('Пользователь с данным email уже существует')
        return value

    def validate(self, attrs):
        if attrs['password'] != attrs.pop('password2'):
            raise serializers.ValidationError('Введенные пароли не совпадают')
        return attrs

    def create(self, validate_data):
        user = User.objects.create_user(
            email=validate_data['email'],
            username=validate_data.get('username', ''),
            password=validate_data['password']
        )

        return user


class RegisterResponseSerializer(serializers.Serializer):
    status = serializers.CharField()
    tokens = serializers.DictField(child=serializers.CharField())


class LoginSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ('email', 'password')


class UserSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['id', 'role', 'email', 'username', 'telegram_chat_id', 'telegram_username', 'telegram_verified',
                  'shipping_address', 'email_verified', 'created_at']


class UserProfileUpdateSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = ['telegram_username']



