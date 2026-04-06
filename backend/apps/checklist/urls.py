from django.urls import path
from .views import MasterChecklistView, ChecklistVersionListView, ChecklistVersionDetailView

urlpatterns = [
    path("master/", MasterChecklistView.as_view()),
    path("versions/", ChecklistVersionListView.as_view()),
    path("versions/<int:pk>/", ChecklistVersionDetailView.as_view()),
]
