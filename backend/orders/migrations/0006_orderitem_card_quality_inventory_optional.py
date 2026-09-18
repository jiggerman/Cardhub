import django.db.models.deletion
from django.db import migrations, models


def populate_card(apps, schema_editor):
    OrderItem = apps.get_model('orders', 'OrderItem')
    for item in OrderItem.objects.select_related('card_inventory').all():
        item.card_id = item.card_inventory.card_id
        item.quality = item.card_inventory.quality
        item.save(update_fields=['card', 'quality'])


class Migration(migrations.Migration):
    dependencies = [
        ('cards', '0001_initial'),
        ('orders', '0005_alter_orderitem_unit_price'),
    ]

    operations = [
        migrations.AddField(
            model_name='orderitem',
            name='card',
            field=models.ForeignKey(
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                related_name='order_items',
                to='cards.card',
            ),
        ),
        migrations.AddField(
            model_name='orderitem',
            name='quality',
            field=models.CharField(default='NM', max_length=5),
        ),
        migrations.AlterField(
            model_name='orderitem',
            name='card_inventory',
            field=models.ForeignKey(
                blank=True,
                null=True,
                on_delete=django.db.models.deletion.PROTECT,
                to='inventory.cardinventory',
            ),
        ),
        migrations.RunPython(populate_card, migrations.RunPython.noop),
        migrations.AlterField(
            model_name='orderitem',
            name='card',
            field=models.ForeignKey(
                on_delete=django.db.models.deletion.PROTECT,
                related_name='order_items',
                to='cards.card',
            ),
        ),
    ]
