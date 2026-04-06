from django.urls import path
from .views import MyScheduleView, MyScheduleMonthView, NextShowView

urlpatterns = [
    path("", MyScheduleView.as_view()),
    path("next-show/", NextShowView.as_view()),
    path("<int:year>/<int:month>/", MyScheduleMonthView.as_view()),
]
