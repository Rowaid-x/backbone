import django_filters
from .models import Show


class ShowFilter(django_filters.FilterSet):
    start_after = django_filters.DateFilter(field_name="start_date", lookup_expr="gte")
    start_before = django_filters.DateFilter(field_name="start_date", lookup_expr="lte")
    end_after = django_filters.DateFilter(field_name="end_date", lookup_expr="gte")
    end_before = django_filters.DateFilter(field_name="end_date", lookup_expr="lte")

    class Meta:
        model = Show
        fields = ["status", "category", "start_after", "start_before", "end_after", "end_before"]
