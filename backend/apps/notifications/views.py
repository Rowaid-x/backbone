from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.shortcuts import get_object_or_404

from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        notes = Notification.objects.filter(user=request.user)
        return Response(NotificationSerializer(notes, many=True).data)


class NotificationMarkReadView(APIView):
    permission_classes = [IsAuthenticated]

    def post(self, request, pk):
        note = get_object_or_404(Notification, pk=pk, user=request.user)
        note.read = True
        note.save(update_fields=["read"])
        return Response({"status": "ok"})

    def delete(self, request, pk):
        note = get_object_or_404(Notification, pk=pk, user=request.user)
        note.delete()
        from rest_framework import status
        return Response(status=status.HTTP_204_NO_CONTENT)
