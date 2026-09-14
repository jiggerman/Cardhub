from django.contrib import admin
from django.utils.html import format_html
from .models import Card


@admin.register(Card)
class CardAdmin(admin.ModelAdmin):
    list_display = ('name', 'set_code', 'collection_number', 'color', 'card_type', 'preview_image', 'created_at')
    list_filter = ('color', 'set_code', 'card_type')
    search_fields = ('name', 'set_code', 'collection_number', 'card_type')
    readonly_fields = ('created_at', 'updated_at', 'preview_image')
    ordering = ('name', 'set_code')

    def preview_image(self, obj):
        if obj.image_url_normal:
            return format_html('<img src="{}" width="60" height="80" style="object-fit:cover;"/>', obj.image_url_normal)
        return "Нет изображения"

    preview_image.short_description = "Изображение"