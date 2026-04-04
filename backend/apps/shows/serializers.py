from rest_framework import serializers
from .models import Show, ShowCrew, Milestone


class ShowSummarySerializer(serializers.ModelSerializer):
    class Meta:
        model = Show
        fields = ["id", "name", "location", "start_date", "end_date", "status", "category", "drone_count"]


class ShowCrewSerializer(serializers.ModelSerializer):
    user_id = serializers.UUIDField(source="user.id", read_only=True)
    full_name = serializers.CharField(source="user.full_name", read_only=True)
    email = serializers.EmailField(source="user.email", read_only=True)
    avatar_url = serializers.URLField(source="user.avatar_url", read_only=True)
    user_role = serializers.CharField(source="user.role", read_only=True)

    class Meta:
        model = ShowCrew
        fields = ["id", "user_id", "full_name", "email", "avatar_url", "user_role", "role", "is_lead"]


class MilestoneSerializer(serializers.ModelSerializer):
    class Meta:
        model = Milestone
        fields = ["id", "name", "due_date", "completed_at", "assigned_to"]


class ShowListSerializer(serializers.ModelSerializer):
    crew_count = serializers.SerializerMethodField()

    class Meta:
        model = Show
        fields = [
            "id", "name", "location", "city", "country",
            "start_date", "end_date", "drone_count",
            "status", "category",
            "health", "permit_status", "production_status",
            "design_status", "scheduling_status", "routing_status", "safety_status",
            "notes", "crew_count", "created_at", "updated_at",
        ]

    def get_crew_count(self, obj):
        return obj.crew.count()


class ShowDetailSerializer(ShowListSerializer):
    crew = ShowCrewSerializer(many=True, read_only=True)
    milestones = MilestoneSerializer(many=True, read_only=True)

    class Meta(ShowListSerializer.Meta):
        fields = ShowListSerializer.Meta.fields + ["crew", "milestones"]
