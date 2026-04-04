from rest_framework import serializers
from .models import Action


class ActionSerializer(serializers.ModelSerializer):
    assigned_to_name = serializers.CharField(source="assigned_to.full_name", read_only=True, default=None)
    show_name = serializers.CharField(source="show.name", read_only=True, default=None)

    class Meta:
        model = Action
        fields = [
            "id", "show", "show_name", "assigned_to", "assigned_to_name",
            "title", "description", "type", "status",
            "due_date", "completed_at", "created_at", "updated_at",
        ]
        read_only_fields = ["created_at", "updated_at", "completed_at"]
