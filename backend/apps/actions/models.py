import uuid
from django.db import models
from django.conf import settings


class Action(models.Model):
    class Status(models.TextChoices):
        OPEN = "open", "Open"
        IN_PROGRESS = "in_progress", "In Progress"
        OVERDUE = "overdue", "Overdue"
        COMPLETED = "completed", "Completed"

    class ActionType(models.TextChoices):
        GENERAL = "general", "General"
        PERMIT = "permit", "Permit"
        LOGISTICS = "logistics", "Logistics"
        DESIGN = "design", "Design"
        SAFETY = "safety", "Safety"
        TRAVEL = "travel", "Travel"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    show = models.ForeignKey(
        "shows.Show", on_delete=models.CASCADE,
        related_name="actions", null=True, blank=True
    )
    assigned_to = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name="assigned_actions"
    )
    created_by = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.SET_NULL,
        null=True, blank=True, related_name="created_actions"
    )
    title = models.CharField(max_length=500)
    description = models.TextField(blank=True)
    type = models.CharField(max_length=20, choices=ActionType.choices, default=ActionType.GENERAL)
    status = models.CharField(max_length=20, choices=Status.choices, default=Status.OPEN)
    due_date = models.DateField(null=True, blank=True)
    completed_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        ordering = ["due_date", "created_at"]
        indexes = [
            models.Index(fields=["assigned_to", "status"]),
            models.Index(fields=["show", "status"]),
        ]

    def __str__(self):
        return self.title
