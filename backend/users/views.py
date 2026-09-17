from django.contrib.auth import authenticate
from drf_spectacular.utils import extend_schema, OpenApiResponse
from rest_framework import status, permissions
from rest_framework.response import Response
from rest_framework.views import APIView
from .serializers import (
    RegisterUserSerializer, RegisterResponseSerializer, LoginSerializer, UserSerializer,
    UserProfileUpdateSerializer, LogoutSerializer, LogoutResponseSerializer,
)
from rest_framework_simplejwt.tokens import RefreshToken
from .models import User


class UserRegistration(APIView):
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Регистрация пользователя",
        description="Создаёт нового пользователя с уникальным email, роль по стандарту: User.",
        request=RegisterUserSerializer,
        responses={
            201: OpenApiResponse(response=RegisterResponseSerializer, description="Пользователь успешно создан"),
            400: OpenApiResponse(description="Ошибки валидации")
        }
    )
    def post(self, request):
        serializer = RegisterUserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            refresh = RefreshToken.for_user(user)
            refresh.payload.update({
                'user_id': user.id,
                'email': user.email
            })

            return Response(
                {
                    "status": "Пользователь создан",
                    "tokens": {
                        'refresh': str(refresh),
                        'access': str(refresh.access_token),
                    }
                 },
                status=status.HTTP_201_CREATED
            )

        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)


class UserLogin(APIView):
    permission_classes = [permissions.AllowAny]

    @extend_schema(
        summary="Вход в аккаунт",
        description="Вход в аккаунт по почте и паролю",
        request=LoginSerializer,
        responses={
            200: OpenApiResponse(response=RegisterResponseSerializer, description="Вход успешный"),
            400: OpenApiResponse(description="Ошибки входа")
        }
    )
    def post(self, request):
        data = request.data
        email = data.get('email')
        password = data.get('password')

        if email is None or password is None:
            return Response({'error': 'Не все поля заполнены'}, status.HTTP_400_BAD_REQUEST)

        user = authenticate(email=email, password=password)

        if user is None:
            return Response({'error': 'Неверные данные'}, status.HTTP_401_UNAUTHORIZED)

        refresh = RefreshToken.for_user(user)
        refresh.payload.update({
            'user_id': user.id,
            'email': user.email
        })

        return Response(
            {
                "status": "Успешный вход",
                "tokens": {
                    'refresh': str(refresh),
                    'access': str(refresh.access_token),
                }
            },
            status=status.HTTP_200_OK
        )


class UserLogout(APIView):
    @extend_schema(
        summary="Выход из аккаунта",
        description="Выход из аккаунта по refresh token",
        request=LogoutSerializer,
        responses={
            200: OpenApiResponse(response=LogoutResponseSerializer, description="Выход успешный"),
            400: OpenApiResponse(description="Ошибки входа")
        }
    )
    def post(self, request):
        refresh_token = request.data.get('refresh_token')
        if not refresh_token:
            return Response(
                {'error': 'Необходим Refresh token'},
                status=status.HTTP_400_BAD_REQUEST
            )
        try:
            token = RefreshToken(refresh_token)
            token.blacklist()
        except Exception as e:
            return Response(
                {'error': 'Неверный Refresh token'},
                status=status.HTTP_400_BAD_REQUEST
            )

        return Response({'success': 'Выход успешен'}, status=status.HTTP_200_OK)


class UserDetail(APIView):
    @extend_schema(
        summary="Получение информации о пользователе",
        description="Возвращает информацию о пользователе по его ID.",
        responses={
            200: OpenApiResponse(response=UserSerializer, description="Информация о пользователе"),
            404: OpenApiResponse(description="Пользователь не найден")
        }
    )
    def get(self, request, user_id):
        try:
            user = User.objects.get(id=user_id)
        except User.DoesNotExist:
            return Response({"error": "Пользователь не найден"}, status=status.HTTP_404_NOT_FOUND)
        serializer = UserSerializer(user)
        return Response(serializer.data)


class CurrentUserView(APIView):
    @extend_schema(
        summary="Текущий пользователь",
        description="Возвращает информацию о пользователе, авторизованном по access token.",
        responses={200: OpenApiResponse(response=UserSerializer, description="Информация о пользователе")}
    )
    def get(self, request):
        serializer = UserSerializer(request.user)
        return Response(serializer.data)

    @extend_schema(
        summary="Обновление профиля",
        description="Обновляет редактируемые пользователем поля профиля (сейчас — Telegram username).",
        request=UserProfileUpdateSerializer,
        responses={
            200: OpenApiResponse(response=UserSerializer, description="Профиль обновлён"),
            400: OpenApiResponse(description="Ошибки валидации")
        }
    )
    def patch(self, request):
        serializer = UserProfileUpdateSerializer(request.user, data=request.data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(UserSerializer(request.user).data)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
