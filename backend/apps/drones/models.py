import uuid
from django.db import models


class DroneFleet(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    geography = models.CharField(max_length=100, blank=True)
    total_count = models.PositiveIntegerField(default=0)

    def __str__(self):
        return self.name


class DroneReservation(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    fleet = models.ForeignKey(DroneFleet, on_delete=models.CASCADE, related_name="reservations")
    show = models.ForeignKey("shows.Show", on_delete=models.CASCADE, related_name="drone_reservations", null=True, blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    reserved_count = models.PositiveIntegerField(default=0)
    remaining_count = models.PositiveIntegerField(default=0)
    notes = models.TextField(blank=True)

    def __str__(self):
        return f"{self.fleet.name} @ {self.show}"
