from django.utils import timezone
from rest_framework import generics, permissions, status
from rest_framework.response import Response
from rest_framework.views import APIView
from .models import Notification
from .serializers import NotificationSerializer


class NotificationListView(generics.ListAPIView):
    serializer_class = NotificationSerializer
    permission_classes = [permissions.IsAuthenticated]

    def get_queryset(self):
        return Notification.objects.filter(user=self.request.user)


class MarkNotificationReadView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def patch(self, request, pk):
        try:
            n = Notification.objects.get(pk=pk, user=request.user)
            n.read_at = timezone.now()
            n.save(update_fields=["read_at"])
            return Response({"status": "ok"})
        except Notification.DoesNotExist:
            return Response(status=status.HTTP_404_NOT_FOUND)


class RegisterFCMTokenView(APIView):
    permission_classes = [permissions.IsAuthenticated]

    def post(self, request):
        token = request.data.get("token", "").strip()
        if token:
            request.user.fcm_token = token
            request.user.save(update_fields=["fcm_token"])
        return Response({"status": "ok"})
