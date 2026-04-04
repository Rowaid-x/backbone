from django.urls import path
from apps.accounts.views import MeView, UserListView, UserDetailView

urlpatterns = [
    path("me/", MeView.as_view(), name="user_me"),
    path("", UserListView.as_view(), name="user_list"),
    path("<uuid:pk>/", UserDetailView.as_view(), name="user_detail"),
]
