"""
Celery tasks for schedule sync and end-of-day notifications.

Schedule sync: runs every hour, pulls the Google Sheet, detects changes,
accumulates a pending_changes dict on the latest ScheduleSync record.

End-of-day notification: runs at 21:00 UTC (midnight Qatar UTC+3),
flushes pending_changes and sends one FCM push per affected user.
"""
import hashlib
import json
import os
import logging
from datetime import date

from celery import shared_task
from django.utils import timezone

from apps.accounts.models import User
from apps.notifications.models import Notification
from .models import ScheduleEntry, ScheduleSync, EntryType

logger = logging.getLogger(__name__)

# ─── Cell classification ──────────────────────────────────────────────────────

def _classify(value, fill_rgb):
    """Map a raw cell value + fill color to an EntryType."""
    if value is None:
        return EntryType.FREE, ""
    val = str(value).strip()
    if not val:
        return EntryType.FREE, ""
    if val.lower() == "x":
        return EntryType.BLACKED_OUT, ""
    if val.lower() == "travel":
        return EntryType.TRAVEL, "Travel"
    return EntryType.SHOW, val


# ─── Sheet parsing ────────────────────────────────────────────────────────────

def _parse_sheet():
    """
    Returns: dict[sheet_name_str -> list[dict(date, entry_type, label)]]
    e.g. {"Rowaid Hourani": [{"date": date(2026,1,17), "entry_type": "show", "label": "QFC - Doha"}, ...]}
    """
    import gspread
    from google.oauth2.service_account import Credentials

    sa_json = os.environ.get("GOOGLE_SERVICE_ACCOUNT_JSON", "")
    if not sa_json:
        logger.warning("GOOGLE_SERVICE_ACCOUNT_JSON not set — skipping sheet sync")
        return {}

    creds = Credentials.from_service_account_info(
        json.loads(sa_json),
        scopes=["https://www.googleapis.com/auth/spreadsheets.readonly"],
    )
    gc = gspread.authorize(creds)
    sheet_id = os.environ.get("SCHEDULE_SHEET_ID", "")
    wb = gc.open_by_key(sheet_id)
    ws = wb.worksheet("Test")

    all_values = ws.get_all_values()
    if len(all_values) < 3:
        return {}

    # Row 3 (index 2): col index 3+ are date strings
    date_row = all_values[2]
    col_dates = {}
    for col_idx, cell in enumerate(date_row):
        if col_idx < 3:
            continue
        try:
            # gspread returns strings; dates come as "2026-01-01" or serial
            from dateutil.parser import parse as dateparse
            col_dates[col_idx] = dateparse(cell).date()
        except Exception:
            pass

    result = {}
    for row in all_values[3:]:
        if len(row) < 3:
            continue
        name = row[2].strip()
        if not name or name in ("NAME", "SCHEDULE APPROVED") or "Region" in name:
            continue
        entries = []
        for col_idx, dt in col_dates.items():
            if col_idx >= len(row):
                continue
            val = row[col_idx].strip() if row[col_idx] else None
            entry_type, label = _classify(val, None)
            if entry_type != EntryType.FREE:
                entries.append({"date": dt, "entry_type": entry_type, "label": label})
        if entries:
            result[name] = entries

    return result


# ─── Main sync task ───────────────────────────────────────────────────────────

@shared_task
def sync_schedule():
    try:
        parsed = _parse_sheet()
    except Exception as exc:
        logger.error("Sheet parse failed: %s", exc)
        return

    raw_hash = hashlib.sha256(json.dumps(parsed, default=str, sort_keys=True).encode()).hexdigest()

    sync_qs = ScheduleSync.objects.order_by("-synced_at")
    last_sync = sync_qs.first()

    if last_sync and last_sync.sheet_hash == raw_hash:
        # Nothing changed
        ScheduleSync.objects.create(sheet_hash=raw_hash, pending_changes=last_sync.pending_changes)
        return

    # Detect per-user changes
    pending = last_sync.pending_changes.copy() if last_sync else {}

    for sheet_name, entries in parsed.items():
        try:
            user = User.objects.get(sheet_name=sheet_name)
        except User.DoesNotExist:
            continue

        for entry_data in entries:
            dt = entry_data["date"]
            new_type = entry_data["entry_type"]
            new_label = entry_data["label"]

            existing = ScheduleEntry.objects.filter(user=user, date=dt).first()
            changed = (
                existing is None
                or existing.entry_type != new_type
                or existing.label != new_label
            )
            if changed:
                ScheduleEntry.objects.update_or_create(
                    user=user,
                    date=dt,
                    defaults={"entry_type": new_type, "label": new_label},
                )
                user_key = str(user.id)
                if user_key not in pending:
                    pending[user_key] = []
                pending[user_key].append({
                    "date": str(dt),
                    "entry_type": new_type,
                    "label": new_label,
                })

    ScheduleSync.objects.create(sheet_hash=raw_hash, pending_changes=pending)


# ─── End-of-day notification task ────────────────────────────────────────────

@shared_task
def send_eod_notifications():
    """
    Runs at 21:00 UTC (midnight Qatar).
    Sends one notification per user who had schedule changes today.
    """
    last_sync = ScheduleSync.objects.order_by("-synced_at").first()
    if not last_sync or not last_sync.pending_changes:
        return

    pending = last_sync.pending_changes

    for user_id_str, changes in pending.items():
        try:
            user = User.objects.get(id=int(user_id_str))
        except User.DoesNotExist:
            continue

        count = len(changes)
        title = "Schedule Updated"
        body = (
            f"Your schedule has {count} change{'s' if count > 1 else ''}. Tap to review."
        )

        Notification.objects.create(user=user, title=title, body=body)

        # FCM push if token exists
        if user.fcm_token:
            _send_fcm(user.fcm_token, title, body)

    # Clear pending changes
    last_sync.pending_changes = {}
    last_sync.save(update_fields=["pending_changes"])


def _send_fcm(token, title, body):
    try:
        import firebase_admin
        from firebase_admin import messaging, credentials
        import json, os

        creds_json = os.environ.get("FIREBASE_CREDENTIALS_JSON", "")
        if not creds_json:
            return

        if not firebase_admin._apps:
            cred = credentials.Certificate(json.loads(creds_json))
            firebase_admin.initialize_app(cred)

        message = messaging.Message(
            notification=messaging.Notification(title=title, body=body),
            token=token,
        )
        messaging.send(message)
    except Exception as exc:
        logger.warning("FCM send failed: %s", exc)
