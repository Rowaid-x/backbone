from django.db import models
from apps.accounts.models import User


class ChecklistSheet(models.TextChoices):
    ONE_PAGE = "one_page", "One-Page Checklist"
    SETUP = "setup", "Setup Checklist"
    FLIGHT = "flight", "Flight Checklist"
    POST_SHOW = "post_show", "Post-Show Checklist"
    MULTI_SHOW = "multi_show", "Multi-Show Flight Checklist"
    EMERGENCY = "emergency", "Emergency Checklist"


class MasterItem(models.Model):
    """One item from the source checklist sheet. Read-only — set by admin import."""
    sheet = models.CharField(max_length=20, choices=ChecklistSheet.choices)
    section = models.CharField(max_length=200, blank=True)  # e.g. "1. UAS System"
    order = models.PositiveIntegerField()
    label = models.CharField(max_length=300)
    default_value = models.CharField(max_length=200, blank=True)  # e.g. "4.5 m/s"
    is_configurable = models.BooleanField(default=False)  # True for value-bearing items

    class Meta:
        ordering = ["sheet", "order"]

    def __str__(self):
        return f"[{self.sheet}] {self.section} – {self.label}"


class ChecklistVersion(models.Model):
    """A named copy of a checklist with overridden values. Global — visible to all users."""
    name = models.CharField(max_length=150, unique=True)  # e.g. "Fever Melbourne"
    sheet = models.CharField(max_length=20, choices=ChecklistSheet.choices)
    created_by = models.ForeignKey(User, on_delete=models.SET_NULL, null=True, related_name="created_versions")
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    def __str__(self):
        return self.name


class VersionItem(models.Model):
    """Overridden value for one item in a named version."""
    version = models.ForeignKey(ChecklistVersion, on_delete=models.CASCADE, related_name="items")
    master_item = models.ForeignKey(MasterItem, on_delete=models.CASCADE)
    label = models.CharField(max_length=300)        # can be renamed
    value = models.CharField(max_length=200, blank=True)  # overridden value

    class Meta:
        unique_together = ("version", "master_item")

    def __str__(self):
        return f"{self.version.name} – {self.label}"
