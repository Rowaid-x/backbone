import uuid
from django.db import models
from django.conf import settings


class TravelEntry(models.Model):
    class TravelType(models.TextChoices):
        FLIGHT = "flight", "Flight"
        HOTEL = "hotel", "Hotel"
        RENTAL_CAR = "rental_car", "Rental Car"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    show = models.ForeignKey("shows.Show", on_delete=models.CASCADE, related_name="travel_entries")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="travel_entries")
    type = models.CharField(max_length=20, choices=TravelType.choices)
    details = models.JSONField(default=dict)
    date_start = models.DateField(null=True, blank=True)
    date_end = models.DateField(null=True, blank=True)
    additional_people = models.JSONField(default=list)
    created_at = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f"{self.user.full_name} - {self.type} @ {self.show}"
