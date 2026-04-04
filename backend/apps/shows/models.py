import uuid
from django.db import models
from django.conf import settings


class Show(models.Model):
    class Status(models.TextChoices):
        PROPOSED = "proposed", "Proposed"
        CONFIRMED = "confirmed", "Confirmed"
        IN_PROGRESS = "in_progress", "In Progress"
        COMPLETED = "completed", "Completed"
        CANCELLED = "cancelled", "Cancelled"

    class Category(models.TextChoices):
        FEV = "FEV", "FEV"
        NOO = "NOO", "NOO"
        NSS = "NSS", "NSS"
        MDS = "MDS", "MDS"
        OTHER = "OTHER", "Other"

    class HealthStatus(models.TextChoices):
        NOT_STARTED = "not_started", "Not Started"
        PENDING = "pending", "Pending"
        IN_PROGRESS = "in_progress", "In Progress"
        NEEDS_ATTENTION = "needs_attention", "Needs Attention"
        DONE = "done", "Done"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    name = models.CharField(max_length=255)
    location = models.CharField(max_length=255, blank=True)
    city = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    start_date = models.DateField(null=True, blank=True)
    end_date = models.DateField(null=True, blank=True)
    drone_count = models.PositiveIntegerField(default=0)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.PROPOSED)
    category = models.CharField(max_length=10, choices=Category.choices, default=Category.OTHER)

    # Health tracking
    health = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)
    permit_status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)
    production_status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)
    design_status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)
    scheduling_status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)
    routing_status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)
    safety_status = models.CharField(max_length=20, choices=HealthStatus.choices, default=HealthStatus.NOT_STARTED)

    notes = models.TextField(blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["start_date"]
        indexes = [
            models.Index(fields=["status", "start_date"]),
            models.Index(fields=["category"]),
        ]

    def __str__(self):
        return f"{self.name} ({self.start_date})"


class ShowCrew(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    show = models.ForeignKey(Show, on_delete=models.CASCADE, related_name="crew")
    user = models.ForeignKey(settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="show_crew")
    role = models.CharField(max_length=100, blank=True)
    is_lead = models.BooleanField(default=False)

    class Meta:
        unique_together = [("show", "user")]

    def __str__(self):
        return f"{self.user.full_name} @ {self.show.name}"


class Milestone(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    show = models.ForeignKey(Show, on_delete=models.CASCADE, related_name="milestones", null=True, blank=True)
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name="milestones"
    )
    name = models.CharField(max_length=255)
    due_date = models.DateField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["due_date"]

    def __str__(self):
        return self.name
