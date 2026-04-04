import uuid
from django.db import models


class PilotTableSnapshot(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sheet_id = models.CharField(max_length=255)
    tab_name = models.CharField(max_length=255, default="Sheet1")
    snapshot_hash = models.CharField(max_length=64)
    row_data = models.JSONField(default=list)
    captured_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        ordering = ["-captured_at"]

    def __str__(self):
        return f"{self.sheet_id} @ {self.captured_at}"


class PilotChangeLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    snapshot = models.ForeignKey(PilotTableSnapshot, on_delete=models.CASCADE, related_name="changes")
    change_type = models.CharField(max_length=20)  # added / removed / modified
    pilot_name = models.CharField(max_length=255)
    field_changed = models.CharField(max_length=255, blank=True)
    old_value = models.TextField(blank=True)
    new_value = models.TextField(blank=True)
    logged_at = models.DateTimeField(auto_now_add=True)


class MidnightNotificationLog(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    sheet_id = models.CharField(max_length=255)
    sent_at = models.DateTimeField(auto_now_add=True)
    changes_summary = models.JSONField(default=dict)
    recipient_count = models.IntegerField(default=0)
