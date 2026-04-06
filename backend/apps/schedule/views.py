from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from django.utils import timezone

from .models import ScheduleEntry, EntryType
from .serializers import ScheduleEntrySerializer


class MyScheduleView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = timezone.localdate()
        entries = ScheduleEntry.objects.filter(user=request.user, date__gte=today).order_by("date")
        return Response(ScheduleEntrySerializer(entries, many=True).data)


class MyScheduleMonthView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, year, month):
        entries = ScheduleEntry.objects.filter(
            user=request.user,
            date__year=year,
            date__month=month,
        ).order_by("date")
        return Response(ScheduleEntrySerializer(entries, many=True).data)


class NextShowView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        today = timezone.localdate()
        entry = ScheduleEntry.objects.filter(
            user=request.user,
            date__gte=today,
            entry_type=EntryType.SHOW,
        ).first()
        if not entry:
            return Response(None)
        return Response(ScheduleEntrySerializer(entry).data)
