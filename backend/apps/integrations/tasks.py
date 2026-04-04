"""
Phase 2 Celery tasks for Google Sheets pilot table sync.
Stubs only — implementation in Phase 2.
"""
from celery import shared_task


@shared_task
def poll_pilot_sheet():
    """
    Polls the configured Google Sheet every 30 minutes.
    Detects changes and writes to PilotChangeLog.
    Does NOT send notifications — that's midnight's job.
    """
    pass  # Phase 2


@shared_task
def send_midnight_pilot_notifications():
    """
    Runs once at midnight (00:00 UTC via Celery Beat).
    Reads change log from last 24h and sends one FCM push to all pilots.
    Idempotent: writes MidnightNotificationLog row first.
    """
    pass  # Phase 2
