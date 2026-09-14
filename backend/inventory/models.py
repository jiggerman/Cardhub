from django.db import models


class CardInventory(models.Model):
    QUALITY_CHOICES = [('NM', 'NM'), ('SP', 'SP'), ('HP', 'HP'), ('MP', 'MP'), ('DM', 'DM')]

    card = models.ForeignKey('cards.Card', on_delete=models.CASCADE, related_name='inventory')
    lang = models.CharField(max_length=15, default='en')
    quality = models.CharField(max_length=5, choices=QUALITY_CHOICES)
    foil = models.BooleanField(default=False)
    quantity = models.PositiveIntegerField(default=0)
    price = models.DecimalField(max_digits=10, decimal_places=2)
    owner = models.ForeignKey('users.User', on_delete=models.SET_NULL, null=True, related_name='inventory')
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return self.card.__str__()
