from django.contrib import admin
from .models import ScheduleEntry, ScheduleSync


@admin.register(ScheduleEntry)
class ScheduleEntryAdmin(admin.ModelAdmin):
    list_display = ["user", "date", "entry_type", "label"]
    list_filter = ["entry_type", "date"]
    search_fields = ["user__name", "user__sheet_name", "label"]


@admin.register(ScheduleSync)
class ScheduleSyncAdmin(admin.ModelAdmin):
    list_display = ["synced_at", "sheet_hash"]
    readonly_fields = ["synced_at", "sheet_hash", "pending_changes"]
