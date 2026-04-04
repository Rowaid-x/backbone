from django.contrib import admin
from .models import Action


@admin.register(Action)
class ActionAdmin(admin.ModelAdmin):
    list_display = ["title", "type", "status", "assigned_to", "show", "due_date"]
    list_filter = ["status", "type"]
    search_fields = ["title"]
    autocomplete_fields = ["assigned_to", "show"]
