from django.contrib import admin
from django.utils import timezone
from .models import Order, OrderItem


class OrderItemInline(admin.TabularInline):
    model = OrderItem
    extra = 1
    fields = ('card_inventory', 'quantity', 'unit_price')
    readonly_fields = ('subtotal',)
    autocomplete_fields = ('card_inventory',)

    def has_add_permission(self, request, obj=None):
        return True


@admin.register(Order)
class OrderAdmin(admin.ModelAdmin):
    list_display = ('id', 'orderType', 'user', 'status', 'tracking_number', 'created_at')
    list_filter = ('status', 'orderType', 'created_at')
    search_fields = ('user__email', 'user__username', 'tracking_number')
    readonly_fields = ('created_at',)
    inlines = [OrderItemInline]
    ordering = ('-created_at',)

    actions = ['mark_as_assembly', 'mark_as_in_transit', 'mark_as_delivered']

    def mark_as_assembly(self, request, queryset):
        queryset.update(status='assembly')

    mark_as_assembly.short_description = "Перевести в статус 'Сборка'"

    def mark_as_in_transit(self, request, queryset):
        queryset.update(status='in_transit')

    mark_as_in_transit.short_description = "Перевести в статус 'В доставке'"

    def mark_as_delivered(self, request, queryset):
        queryset.update(status='delivered')

    mark_as_delivered.short_description = "Перевести в статус 'Доставлен'"

    def get_queryset(self, request):
        qs = super().get_queryset(request)
        if request.user.role == 'picker':
            return qs.filter(status='assembly')
        return qs

    def has_change_permission(self, request, obj=None):
        if request.user.role == 'picker':
            return obj.status == 'assembly' if obj else True
        return request.user.role in ('admin', 'moderator')



@admin.register(OrderItem)
class OrderItemAdmin(admin.ModelAdmin):
    list_display = ('order', 'card_inventory', 'quantity', 'unit_price', 'subtotal')
    autocomplete_fields = ('order', 'card_inventory')
    readonly_fields = ('subtotal',)
