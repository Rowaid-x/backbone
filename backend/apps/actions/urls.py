from django.urls import path
from .views import ActionListView, ActionUpdateView

urlpatterns = [
    path("", ActionListView.as_view(), name="action_list"),
    path("<uuid:pk>/", ActionUpdateView.as_view(), name="action_update"),
]
