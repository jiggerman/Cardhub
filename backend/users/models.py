from django.db import models
from django.contrib.auth.models import AbstractUser

from .managers import UserManager


class User(AbstractUser):
    ROLE_CHOICES = [('user', 'User'), ('moderator', 'Moderator'), ('importer', 'Importer'), ('admin', 'Admin')]
    role = models.CharField(max_length=20, choices=ROLE_CHOICES, default='user')

    email = models.EmailField(unique=True)
    username = models.CharField(max_length=150, blank=True, null=True, unique=False)

    telegram_chat_id = models.BigIntegerField(null=True, blank=True)
    telegram_username = models.CharField(null=True, blank=True)
    telegram_verified = models.BooleanField(default=False)

    shipping_address = models.JSONField(null=True, blank=True)
    email_verified = models.BooleanField(default=False)

    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    USERNAME_FIELD = 'email'
    REQUIRED_FIELDS = []

    objects = UserManager()

    def is_moderator(self):
        return self.role in ('admin', 'moderator')

    def is_picker(self):
        return self.role in ('admin', 'moderator', 'picker')


