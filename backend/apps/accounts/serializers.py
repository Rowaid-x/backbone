from rest_framework import serializers
from .models import User


class UserListSerializer(serializers.ModelSerializer):
    class Meta:
        model = User
        fields = [
            "id", "email", "full_name", "role", "crew_role",
            "country", "state", "city", "avatar_url",
            "faa_level", "mmac_level", "is_active", "date_joined",
        ]


class UserDetailSerializer(serializers.ModelSerializer):
    shows_count = serializers.SerializerMethodField()
    upcoming_shows = serializers.SerializerMethodField()
    previous_shows = serializers.SerializerMethodField()

    class Meta:
        model = User
        fields = [
            "id", "email", "full_name", "role", "crew_role",
            "country", "state", "city", "avatar_url",
            "faa_level", "mmac_level", "is_active", "date_joined",
            "shows_count", "upcoming_shows", "previous_shows",
        ]

    def get_shows_count(self, obj):
        return obj.show_crew.count()

    def get_upcoming_shows(self, obj):
        from apps.shows.serializers import ShowSummarySerializer
        from django.utils import timezone
        shows = obj.show_crew.filter(
            show__start_date__gte=timezone.now().date()
        ).select_related("show").order_by("show__start_date")[:5]
        return ShowSummarySerializer([sc.show for sc in shows], many=True).data

    def get_previous_shows(self, obj):
        from apps.shows.serializers import ShowSummarySerializer
        from django.utils import timezone
        shows = obj.show_crew.filter(
            show__end_date__lt=timezone.now().date()
        ).select_related("show").order_by("-show__end_date")[:5]
        return ShowSummarySerializer([sc.show for sc in shows], many=True).data


class UserMeSerializer(UserDetailSerializer):
    """Current user — same as detail but writable for profile updates."""

    class Meta(UserDetailSerializer.Meta):
        read_only_fields = ["id", "email", "date_joined"]
