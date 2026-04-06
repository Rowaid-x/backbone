from rest_framework import serializers
from .models import MasterItem, ChecklistVersion, VersionItem


class MasterItemSerializer(serializers.ModelSerializer):
    class Meta:
        model = MasterItem
        fields = ["id", "sheet", "section", "order", "label", "default_value", "is_configurable"]


class VersionItemSerializer(serializers.ModelSerializer):
    master_item_id = serializers.PrimaryKeyRelatedField(
        source="master_item", queryset=MasterItem.objects.all()
    )

    class Meta:
        model = VersionItem
        fields = ["id", "master_item_id", "label", "value"]


class ChecklistVersionSerializer(serializers.ModelSerializer):
    items = VersionItemSerializer(many=True, read_only=True)
    created_by_name = serializers.CharField(source="created_by.name", read_only=True)

    class Meta:
        model = ChecklistVersion
        fields = ["id", "name", "sheet", "created_by_name", "created_at", "updated_at", "items"]


class ChecklistVersionWriteSerializer(serializers.ModelSerializer):
    items = VersionItemSerializer(many=True)

    class Meta:
        model = ChecklistVersion
        fields = ["name", "sheet", "items"]

    def create(self, validated_data):
        items_data = validated_data.pop("items")
        version = ChecklistVersion.objects.create(
            created_by=self.context["request"].user,
            **validated_data,
        )
        for item in items_data:
            VersionItem.objects.create(version=version, **item)
        return version

    def update(self, instance, validated_data):
        items_data = validated_data.pop("items", [])
        instance.name = validated_data.get("name", instance.name)
        instance.save()
        if items_data:
            instance.items.all().delete()
            for item in items_data:
                VersionItem.objects.create(version=instance, **item)
        return instance
