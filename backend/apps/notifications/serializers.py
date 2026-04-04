from rest_framework import serializers
from .models import Notification


class NotificationSerializer(serializers.ModelSerializer):
    related_show_name = serializers.CharField(source="related_show.name", read_only=True, default=None)

    class Meta:
        model = Notification
        fields = ["id", "title", "body", "type", "related_show", "related_show_name", "read_at", "created_at"]
        read_only_fields = ["created_at"]
