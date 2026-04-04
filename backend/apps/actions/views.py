from django.utils import timezone
from rest_framework import generics, permissions
from rest_framework.filters import SearchFilter, OrderingFilter
from django_filters.rest_framework import DjangoFilterBackend
from .models import Action
from .serializers import ActionSerializer


class ActionListView(generics.ListAPIView):
    serializer_class = ActionSerializer
    permission_classes = [permissions.IsAuthenticated]
    filter_backends = [DjangoFilterBackend, SearchFilter, OrderingFilter]
    filterset_fields = ["status", "type", "show"]
    search_fields = ["title", "description"]
    ordering_fields = ["due_date", "created_at", "status"]
    ordering = ["due_date"]

    def get_queryset(self):
        qs = Action.objects.select_related("show", "assigned_to")
        mine = self.request.query_params.get("assigned_to")
        if mine == "me":
            qs = qs.filter(assigned_to=self.request.user)
        return qs


class ActionUpdateView(generics.UpdateAPIView):
    serializer_class = ActionSerializer
    permission_classes = [permissions.IsAuthenticated]
    queryset = Action.objects.all()

    def perform_update(self, serializer):
        if serializer.validated_data.get("status") == Action.Status.COMPLETED:
            serializer.save(completed_at=timezone.now())
        else:
            serializer.save()
