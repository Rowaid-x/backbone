import uuid
from django.contrib.auth.models import AbstractBaseUser, BaseUserManager, PermissionsMixin
from django.db import models


class UserManager(BaseUserManager):
    def create_user(self, email, password=None, **extra_fields):
        if not email:
            raise ValueError("Email is required")
        email = self.normalize_email(email)
        user = self.model(email=email, **extra_fields)
        user.set_password(password)
        user.save(using=self._db)
        return user

    def create_superuser(self, email, password=None, **extra_fields):
        extra_fields.setdefault("is_staff", True)
        extra_fields.setdefault("is_superuser", True)
        return self.create_user(email, password, **extra_fields)


class User(AbstractBaseUser, PermissionsMixin):
    class Role(models.TextChoices):
        PILOT = "pilot", "Pilot"
        ARTIST = "artist", "Artist"
        DESIGNER = "designer", "Designer"
        MMTS = "mmts", "MMTS"
        PR = "pr", "PR"
        ADMIN = "admin", "Admin"

    class FAALevel(models.TextChoices):
        NONE = "", "None"
        PART107 = "part107", "Part 107"
        COMMERCIAL = "commercial", "Commercial"

    class MMACLevel(models.TextChoices):
        NONE = "", "None"
        LEVEL1 = "l1", "Level 1"
        LEVEL2 = "l2", "Level 2"
        LEVEL3 = "l3", "Level 3"

    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    email = models.EmailField(unique=True)
    full_name = models.CharField(max_length=255)
    role = models.CharField(max_length=20, choices=Role.choices, default=Role.PILOT)
    crew_role = models.CharField(max_length=100, blank=True)
    country = models.CharField(max_length=100, blank=True)
    state = models.CharField(max_length=100, blank=True)
    city = models.CharField(max_length=100, blank=True)
    avatar_url = models.URLField(blank=True)
    faa_level = models.CharField(max_length=20, choices=FAALevel.choices, blank=True)
    mmac_level = models.CharField(max_length=10, choices=MMACLevel.choices, blank=True)
    fcm_token = models.TextField(blank=True)
    is_active = models.BooleanField(default=True)
    is_staff = models.BooleanField(default=False)
    date_joined = models.DateTimeField(auto_now_add=True)

    USERNAME_FIELD = "email"
    REQUIRED_FIELDS = ["full_name"]

    objects = UserManager()

    class Meta:
        ordering = ["full_name"]

    def __str__(self):
        return f"{self.full_name} ({self.email})"

    @property
    def initials(self):
        parts = self.full_name.split()
        if len(parts) >= 2:
            return f"{parts[0][0]}{parts[-1][0]}".upper()
        return self.full_name[:2].upper()
