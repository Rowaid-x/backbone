from django.db import models
from apps.accounts.models import User


class EntryType(models.TextChoices):
    SHOW = "show", "Show"
    TRAVEL = "travel", "Travel"
    BLACKED_OUT = "blacked_out", "Blacked Out"
    FREE = "free", "Free"


class ScheduleEntry(models.Model):
    """One cell from the Google Sheet for one person on one date."""
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="schedule_entries")
    date = models.DateField(db_index=True)
    entry_type = models.CharField(max_length=20, choices=EntryType.choices, default=EntryType.FREE)
    label = models.CharField(max_length=200, blank=True)  # Show name, "Travel", etc.

    class Meta:
        unique_together = ("user", "date")
        ordering = ["date"]

    def __str__(self):
        return f"{self.user.sheet_name} – {self.date} – {self.entry_type}"


class ScheduleSync(models.Model):
    """Tracks the last time the sheet was synced and stores a hash for change detection."""
    synced_at = models.DateTimeField(auto_now=True)
    sheet_hash = models.CharField(max_length=64, blank=True)  # SHA256 of raw data
    # Pending changes accumulated during the day, sent as one notification at 21:00 UTC
    pending_changes = models.JSONField(default=dict)

    class Meta:
        ordering = ["-synced_at"]

    def __str__(self):
        return f"Sync @ {self.synced_at}"
