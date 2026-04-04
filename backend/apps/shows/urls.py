from django.urls import path
from .views import ShowListView, ShowDetailView

urlpatterns = [
    path("", ShowListView.as_view(), name="show_list"),
    path("<uuid:pk>/", ShowDetailView.as_view(), name="show_detail"),
]
