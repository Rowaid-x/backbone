import uuid
from django.db import models
from django.conf import settings


class Notification(models.Model):
    class NotificationType(models.TextChoices):
        SHOW = "show", "Show"
        ACTION = "action", "Action"
        PILOT_SHEET = "pilot_sheet", "Pilot Sheet"
        GENERAL = "general", "General"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(
        settings.AUTH_USER_MODEL, on_delete=models.CASCADE, related_name="notifications"
    )
    title = models.CharField(max_length=255)
    body = models.TextField()
    type = models.CharField(max_length=20, choices=NotificationType.choices, default=NotificationType.GENERAL)
    related_show = models.ForeignKey(
        "shows.Show", on_delete=models.SET_NULL, null=True, blank=True
    )
    read_at = models.DateTimeField(null=True, blank=True)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-created_at"]
        indexes = [models.Index(fields=["user", "read_at"])]

    def __str__(self):
        return f"{self.user.full_name}: {self.title}"
