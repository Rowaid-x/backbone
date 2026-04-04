from django.contrib import admin
from django.urls import path, include
from drf_spectacular.views import SpectacularAPIView, SpectacularSwaggerView

urlpatterns = [
    path("admin/", admin.site.urls),
    path("api/schema/", SpectacularAPIView.as_view(), name="schema"),
    path("api/docs/", SpectacularSwaggerView.as_view(url_name="schema"), name="swagger-ui"),
    path("api/auth/", include("apps.accounts.urls.auth")),
    path("api/users/", include("apps.accounts.urls.users")),
    path("api/shows/", include("apps.shows.urls")),
    path("api/actions/", include("apps.actions.urls")),
    path("api/notifications/", include("apps.notifications.urls")),
    path("api/drones/", include("apps.drones.urls")),
    path("api/shifts/", include("apps.shifts.urls")),
    path("api/travel/", include("apps.travel.urls")),
    path("api/integrations/", include("apps.integrations.urls")),
]
