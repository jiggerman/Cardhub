from django.contrib import admin
from .models import CardInventory


@admin.register(CardInventory)
class CardInventoryAdmin(admin.ModelAdmin):
    list_display = ('card', 'lang', 'quality', 'foil', 'quantity', 'price', 'owner', 'created_at')
    list_filter = ('quality', 'foil', 'lang', 'owner')
    search_fields = ('card__name', 'card__set_code', 'card__collection_number', 'owner__username', 'owner__email')
    autocomplete_fields = ('card', 'owner')
    readonly_fields = ('created_at',)
    ordering = ('-created_at',)

    # Модератор может менять цены и остатки, сборщик только видит
    def has_change_permission(self, request, obj=None):
        return request.user.role in ('admin', 'moderator', 'importer')

    def has_delete_permission(self, request, obj=None):
        return request.user.role == 'admin'
