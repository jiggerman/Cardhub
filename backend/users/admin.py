from django.contrib import admin
from django.contrib.auth.admin import UserAdmin as BaseUserAdmin
from .models import User


@admin.register(User)
class UserAdmin(BaseUserAdmin):
    list_display = ('username', 'email', 'role', 'email_verified', 'telegram_username', 'created_at')
    list_filter = ('role', 'email_verified', 'telegram_verified', 'is_staff', 'is_superuser', 'created_at')
    search_fields = ('username', 'email', 'telegram_username')
    ordering = ('-created_at',)

    readonly_fields = ('created_at', 'updated_at', 'last_login', 'date_joined')

    fieldsets = BaseUserAdmin.fieldsets + (
        ('Дополнительные данные', {
            'fields': ('role', 'telegram_chat_id', 'telegram_username', 'telegram_verified',
                       'shipping_address', 'email_verified',)
        }),
    )

    def has_change_permission(self, request, obj=None):
        if request.user.role == 'moderator' and obj and obj.role == 'admin':
            return False
        return super().has_change_permission(request, obj)