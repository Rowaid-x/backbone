from rest_framework_simplejwt.views import TokenObtainPairView

# Username aliases — map shorthand usernames to real emails
USERNAME_MAP = {
    "root": "root@backbone.com",
}


class CustomTokenObtainPairView(TokenObtainPairView):
    def post(self, request, *args, **kwargs):
        data = request.data.copy()
        email = data.get("email", "").strip()
        if email in USERNAME_MAP:
            data["email"] = USERNAME_MAP[email]
        request._full_data = data
        return super().post(request, *args, **kwargs)
