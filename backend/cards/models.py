from django.db import models


class Card(models.Model):
    COLOR_CHOICES = [
        ('Colorless', 'Colorless'),
        ('Multicolor', 'Multicolor'),
        ('White', 'White'),
        ('Blue', 'Blue'),
        ('Black', 'Black'),
        ('Red', 'Red'),
        ('Green', 'Green')
    ]

    color = models.CharField(max_length=15, choices=COLOR_CHOICES)
    set_code = models.CharField(max_length=30)
    set_name = models.CharField(max_length=100, blank=True, null=True)
    collection_number = models.CharField()
    name = models.CharField(max_length=255)
    card_type = models.CharField(max_length=255, blank=True, null=True)
    image_url_small = models.URLField(blank=True)
    image_url_normal = models.URLField(blank=True)
    image_url_large = models.URLField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        indexes = [models.Index(fields=['name']), models.Index(fields=['set_code'])]

    def __str__(self):
        return f"{self.name} / {self.set_code} / {self.collection_number}"
