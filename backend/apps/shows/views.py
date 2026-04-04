from rest_framework import generics, permissions
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from .models import Show
from .serializers import ShowListSerializer, ShowDetailSerializer
from .filters import ShowFilter


class ShowListView(generics.ListAPIView):
    queryset = Show.objects.prefetch_related("crew")
    serializer_class = ShowListSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_class = ShowFilter
    search_fields = ["name", "location", "city", "country"]
    ordering_fields = ["start_date", "end_date", "name", "status", "drone_count"]
    ordering = ["start_date"]


class ShowDetailView(generics.RetrieveAPIView):
    queryset = Show.objects.prefetch_related("crew__user", "milestones")
    serializer_class = ShowDetailSerializer
    permission_classes = [permissions.IsAuthenticated]
