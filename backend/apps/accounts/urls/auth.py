from django.urls import path
from rest_framework_simplejwt.views import TokenObtainPairView, TokenRefreshView
from apps.notifications.views import RegisterFCMTokenView

urlpatterns = [
    path("login/", TokenObtainPairView.as_view(), name="token_obtain_pair"),
    path("refresh/", TokenRefreshView.as_view(), name="token_refresh"),
    path("register-fcm-token/", RegisterFCMTokenView.as_view(), name="register_fcm_token"),
]
