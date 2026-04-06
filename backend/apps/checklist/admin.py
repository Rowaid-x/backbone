from django.contrib import admin
from .models import MasterItem, ChecklistVersion, VersionItem


@admin.register(MasterItem)
class MasterItemAdmin(admin.ModelAdmin):
    list_display = ["sheet", "section", "order", "label", "default_value", "is_configurable"]
    list_filter = ["sheet", "is_configurable"]
    ordering = ["sheet", "order"]


class VersionItemInline(admin.TabularInline):
    model = VersionItem
    extra = 0


@admin.register(ChecklistVersion)
class ChecklistVersionAdmin(admin.ModelAdmin):
    list_display = ["name", "sheet", "created_by", "created_at"]
    inlines = [VersionItemInline]
