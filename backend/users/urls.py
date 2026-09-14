from django.urls import path
from .views import UserRegistration, UserLogin, UserLogout, UserDetail, CurrentUserView

urlpatterns = [
    path('register/', UserRegistration.as_view(), name='user-register'),
    path('login/', UserLogin.as_view(), name='user-login'),
    path('logout/', UserLogout.as_view(), name='user-logout'),
    path('user/me/', CurrentUserView.as_view(), name='current-user'),
    path('user/<int:user_id>/', UserDetail.as_view(), name='user-detail')
]

