from django.contrib import admin
from .models import Show, ShowCrew, Milestone


class ShowCrewInline(admin.TabularInline):
    model = ShowCrew
    extra = 0
    autocomplete_fields = ["user"]


class MilestoneInline(admin.TabularInline):
    model = Milestone
    extra = 0


@admin.register(Show)
class ShowAdmin(admin.ModelAdmin):
    list_display = ["name", "category", "status", "start_date", "end_date", "drone_count", "location"]
    list_filter = ["status", "category"]
    search_fields = ["name", "location", "city"]
    ordering = ["start_date"]
    inlines = [ShowCrewInline, MilestoneInline]
