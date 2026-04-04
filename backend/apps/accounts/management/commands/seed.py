"""
python manage.py seed

Creates demo data for Phase 1 development:
- 1 superuser admin
- 10 crew users
- 15 shows with crew assignments
- 20 actions
- 10 notifications
"""
from django.core.management.base import BaseCommand
from django.utils import timezone
import datetime
import random


class Command(BaseCommand):
    help = "Seed development data"

    def handle(self, *args, **options):
        from apps.accounts.models import User
        from apps.shows.models import Show, ShowCrew, Milestone
        from apps.actions.models import Action
        from apps.notifications.models import Notification

        self.stdout.write("Seeding users...")

        admin, _ = User.objects.get_or_create(
            email="admin@novaskystories.com",
            defaults={"full_name": "Admin Nova", "role": "admin", "is_staff": True, "is_superuser": True},
        )
        admin.set_password("admin123")
        admin.save()

        users_data = [
            ("Rowaid Hourani", "rowaid@novaskystories.com", "artist", "QA"),
            ("Addison Mehr", "addison.mehr@novaskystories.com", "pilot", "US"),
            ("Alex Hughes", "alex.hughes@novaskystories.com", "designer", "US"),
            ("Ali Jamalem", "ali@novaskystories.com", "mmts", "AE"),
            ("Ananth Orasappa", "ananth@novaskystories.com", "artist", "IN"),
            ("Andreas Jalainen", "andreas@novaskystories.com", "designer", "DE"),
            ("Andrew Stagee", "andrew.s@novaskystories.com", "pilot", "US"),
            ("Andy Munro", "andy@novaskystories.com", "mmts", "AU"),
            ("Angela van Straten", "angela@novaskystories.com", "designer", "NL"),
            ("Anouk Toebi", "anouk@novaskystories.com", "designer", "NL"),
        ]

        users = []
        for full_name, email, role, country in users_data:
            u, _ = User.objects.get_or_create(
                email=email,
                defaults={"full_name": full_name, "role": role, "country": country},
            )
            u.set_password("password123")
            u.save()
            users.append(u)

        self.stdout.write("Seeding shows...")

        today = timezone.now().date()
        shows_data = [
            ("Book Fair Abu Dhabi", "FEV", "confirmed", "Abu Dhabi", "AE", today - datetime.timedelta(days=60), today - datetime.timedelta(days=55), 800),
            ("FIFA WC Liberty State Park #2", "NOO", "confirmed", "New York", "US", today - datetime.timedelta(days=30), today - datetime.timedelta(days=25), 500),
            ("New York City", "MDS", "in_progress", "New York", "US", today - datetime.timedelta(days=10), today + datetime.timedelta(days=5), 300),
            ("Hamburg", "FEV", "confirmed", "Hamburg", "DE", today + datetime.timedelta(days=10), today + datetime.timedelta(days=15), 600),
            ("Milan", "FEV", "confirmed", "Milan", "IT", today + datetime.timedelta(days=20), today + datetime.timedelta(days=25), 750),
            ("San Diego", "FEV", "proposed", "San Diego", "US", today + datetime.timedelta(days=30), today + datetime.timedelta(days=35), 400),
            ("FFTC Training", "NOO", "confirmed", "Online", "", today + datetime.timedelta(days=7), today + datetime.timedelta(days=8), 0),
            ("Rio de Janeiro", "FEV", "proposed", "Rio", "BR", today + datetime.timedelta(days=45), today + datetime.timedelta(days=50), 900),
            ("Munich", "MDS", "confirmed", "Munich", "DE", today + datetime.timedelta(days=40), today + datetime.timedelta(days=44), 350),
            ("Los Angeles", "FEV", "in_progress", "Los Angeles", "US", today - datetime.timedelta(days=5), today + datetime.timedelta(days=10), 500),
            ("Validation Boulder", "NSS", "proposed", "Boulder", "US", today + datetime.timedelta(days=60), today + datetime.timedelta(days=65), 1000),
            ("Seoul", "FEV", "confirmed", "Seoul", "KR", today + datetime.timedelta(days=80), today + datetime.timedelta(days=85), 750),
            ("Dubai New Year", "FEV", "confirmed", "Dubai", "AE", today + datetime.timedelta(days=90), today + datetime.timedelta(days=95), 1200),
            ("Sao Paulo Festival", "FEV", "proposed", "Sao Paulo", "BR", today + datetime.timedelta(days=110), today + datetime.timedelta(days=115), 600),
            ("Tokyo Olympics Eve", "NOO", "proposed", "Tokyo", "JP", today + datetime.timedelta(days=120), today + datetime.timedelta(days=125), 800),
        ]

        health_choices = [c[0] for c in Show.HealthStatus.choices]
        shows = []
        for name, cat, status, city, country, start, end, drones in shows_data:
            show, _ = Show.objects.get_or_create(
                name=name,
                defaults={
                    "category": cat,
                    "status": status,
                    "city": city,
                    "country": country,
                    "location": f"{city}, {country}".strip(", "),
                    "start_date": start,
                    "end_date": end,
                    "drone_count": drones,
                    "health": random.choice(health_choices),
                    "permit_status": random.choice(health_choices),
                    "production_status": random.choice(health_choices),
                    "design_status": random.choice(health_choices),
                    "scheduling_status": random.choice(health_choices),
                },
            )
            shows.append(show)
            # Assign random crew
            for user in random.sample(users, k=min(4, len(users))):
                ShowCrew.objects.get_or_create(show=show, user=user)

        self.stdout.write("Seeding actions...")

        action_titles = [
            "Submit permit application", "Confirm drone fleet availability",
            "Book crew flights", "Prepare design files", "Schedule safety briefing",
            "Arrange ground transport", "Confirm venue dimensions", "Upload show design",
            "Send logistics brief", "Review routing plan", "Order spare parts",
            "Coordinate with local authority", "Update show timeline", "Finalize music sync",
            "Confirm accommodation", "Review weather forecast", "Test comms equipment",
            "Brief local crew", "Prepare customs docs", "Ship drone cases",
        ]

        for i, title in enumerate(action_titles):
            show = random.choice(shows)
            assigned = random.choice(users)
            status_choice = random.choice([Action.Status.OPEN, Action.Status.IN_PROGRESS, Action.Status.COMPLETED])
            due = today + datetime.timedelta(days=random.randint(-10, 60))
            Action.objects.get_or_create(
                title=title,
                defaults={
                    "show": show,
                    "assigned_to": assigned,
                    "status": status_choice,
                    "type": random.choice([c[0] for c in Action.ActionType.choices]),
                    "due_date": due,
                    "completed_at": timezone.now() if status_choice == Action.Status.COMPLETED else None,
                },
            )

        self.stdout.write("Seeding notifications...")

        rowaid = User.objects.filter(email="rowaid@novaskystories.com").first()
        if rowaid:
            notif_data = [
                ("New show assigned", "You have been added to Dubai New Year show.", "show"),
                ("Action due soon", "Submit permit application is due in 2 days.", "action"),
                ("Pilot sheet updated", "3 pilots updated in the roster.", "pilot_sheet"),
                ("Show confirmed", "Milan show has been confirmed.", "show"),
                ("Action overdue", "Book crew flights is overdue.", "action"),
            ]
            for title, body, ntype in notif_data:
                Notification.objects.get_or_create(
                    user=rowaid,
                    title=title,
                    defaults={"body": body, "type": ntype},
                )

        self.stdout.write(self.style.SUCCESS("Seed complete. Admin: admin@novaskystories.com / admin123"))
