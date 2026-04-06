from rest_framework.views import APIView
from rest_framework.response import Response
from rest_framework.permissions import IsAuthenticated
from rest_framework import status
from django.shortcuts import get_object_or_404

from .models import MasterItem, ChecklistVersion
from .serializers import (
    MasterItemSerializer,
    ChecklistVersionSerializer,
    ChecklistVersionWriteSerializer,
)


class MasterChecklistView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sheet = request.query_params.get("sheet", "flight")
        items = MasterItem.objects.filter(sheet=sheet)
        return Response(MasterItemSerializer(items, many=True).data)


class ChecklistVersionListView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request):
        sheet = request.query_params.get("sheet")
        qs = ChecklistVersion.objects.all()
        if sheet:
            qs = qs.filter(sheet=sheet)
        return Response(ChecklistVersionSerializer(qs, many=True).data)

    def post(self, request):
        serializer = ChecklistVersionWriteSerializer(data=request.data, context={"request": request})
        serializer.is_valid(raise_exception=True)
        version = serializer.save()
        return Response(ChecklistVersionSerializer(version).data, status=status.HTTP_201_CREATED)


class ChecklistVersionDetailView(APIView):
    permission_classes = [IsAuthenticated]

    def get(self, request, pk):
        version = get_object_or_404(ChecklistVersion, pk=pk)
        return Response(ChecklistVersionSerializer(version).data)

    def patch(self, request, pk):
        version = get_object_or_404(ChecklistVersion, pk=pk)
        serializer = ChecklistVersionWriteSerializer(
            version, data=request.data, partial=True, context={"request": request}
        )
        serializer.is_valid(raise_exception=True)
        serializer.save()
        return Response(ChecklistVersionSerializer(version).data)

    def delete(self, request, pk):
        version = get_object_or_404(ChecklistVersion, pk=pk)
        version.delete()
        return Response(status=status.HTTP_204_NO_CONTENT)
