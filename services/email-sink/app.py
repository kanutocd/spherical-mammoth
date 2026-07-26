import hashlib
import hmac
import json
import os
import smtplib
import sqlite3
import threading
from datetime import UTC, datetime, timedelta
from email.message import EmailMessage
from http.server import BaseHTTPRequestHandler, ThreadingHTTPServer
from pathlib import Path


DB_PATH = Path(os.getenv("EMAIL_SINK_DB_PATH", "/data/email-sink.db"))
DELIVERY_SECRET = os.getenv("DELIVERY_SECRET", "")
SMTP_HOST = os.getenv("MAILPIT_SMTP_HOST", "mailpit")
SMTP_PORT = int(os.getenv("MAILPIT_SMTP_PORT", "1025"))
FROM_ADDRESS = os.getenv("EMAIL_FROM_ADDRESS", "no-reply@spherical-mammoth.test")
LOCK = threading.Lock()


def connection():
    db = sqlite3.connect(DB_PATH)
    db.row_factory = sqlite3.Row
    return db


def migrate():
    DB_PATH.parent.mkdir(parents=True, exist_ok=True)
    with connection() as db:
        db.execute(
            """
            CREATE TABLE IF NOT EXISTS deliveries (
              delivery_id TEXT PRIMARY KEY,
              event_id TEXT NOT NULL,
              event_type TEXT NOT NULL,
              status TEXT NOT NULL,
              attempt INTEGER NOT NULL,
              provider_message_id TEXT,
              last_error TEXT,
              updated_at TEXT NOT NULL
            )
            """
        )


def claim_delivery(delivery_id, event_id, event_type, attempt):
    now = datetime.now(UTC)
    stale_before = (now - timedelta(minutes=5)).isoformat()
    with LOCK, connection() as db:
        row = db.execute(
            "SELECT status, updated_at FROM deliveries WHERE delivery_id = ?",
            (delivery_id,),
        ).fetchone()
        if row and row["status"] == "completed":
            return "completed"
        if row and row["status"] == "processing" and row["updated_at"] >= stale_before:
            return "processing"
        db.execute(
            """
            INSERT INTO deliveries
              (delivery_id, event_id, event_type, status, attempt, updated_at)
            VALUES (?, ?, ?, 'processing', ?, ?)
            ON CONFLICT(delivery_id) DO UPDATE SET
              status = 'processing',
              attempt = excluded.attempt,
              last_error = NULL,
              updated_at = excluded.updated_at
            """,
            (delivery_id, event_id, event_type, attempt, now.isoformat()),
        )
    return "claimed"


def finish_delivery(delivery_id, status, provider_message_id=None, error=None):
    with connection() as db:
        db.execute(
            """
            UPDATE deliveries
            SET status = ?, provider_message_id = ?, last_error = ?, updated_at = ?
            WHERE delivery_id = ?
            """,
            (status, provider_message_id, error, datetime.now(UTC).isoformat(), delivery_id),
        )


def render(event):
    data = event["data"]
    display_name = data.get("display_name") or "there"
    event_type = event["event_type"]
    if event_type == "identity.verification_requested":
        subject = "Verify your Spherical Mammoth account"
        verification_url = data.get("verification_url")
        action = f"\n\nContinue verification: {verification_url}" if verification_url else ""
        body = f"Hi {display_name},\n\nYour signup was received.{action}\n"
    elif event_type == "identity.signup_completed":
        subject = "Welcome to Spherical Mammoth"
        body = f"Hi {display_name},\n\nYour account is verified and ready.\n"
    else:
        raise ValueError(f"unsupported event type: {event_type}")
    return data["email"], subject, body


def send_email(recipient, subject, body):
    message = EmailMessage()
    message["From"] = FROM_ADDRESS
    message["To"] = recipient
    message["Subject"] = subject
    message.set_content(body)
    with smtplib.SMTP(SMTP_HOST, SMTP_PORT, timeout=10) as smtp:
        response = smtp.send_message(message)
    return hashlib.sha256(repr(response).encode()).hexdigest()


class Handler(BaseHTTPRequestHandler):
    server_version = "spherical-mammoth-email-sink/0.1"

    def do_GET(self):
        if self.path in ("/health/live", "/health/ready"):
            self.respond(200, {"status": "ok"})
        else:
            self.respond(404, {"error": "not found"})

    def do_POST(self):
        if self.path != "/v1/deliveries":
            self.respond(404, {"error": "not found"})
            return
        content_length = int(self.headers.get("Content-Length", "0"))
        if content_length <= 0 or content_length > 1_048_576:
            self.respond(400, {"error": "invalid content length"})
            return
        body = self.rfile.read(content_length)
        if DELIVERY_SECRET:
            supplied = self.headers.get("X-Mammoth-Signature", "")
            expected = hmac.new(DELIVERY_SECRET.encode(), body, hashlib.sha256).hexdigest()
            if not hmac.compare_digest(supplied, expected):
                self.respond(401, {"error": "invalid signature"})
                return
        try:
            envelope = json.loads(body)
            delivery_id = required_string(envelope, "delivery_id")
            attempt = envelope["attempt"]
            if not isinstance(attempt, int) or attempt < 1:
                raise ValueError("attempt must be a positive integer")
            event = envelope["event"]
            event_id = required_string(event, "event_id")
            event_type = required_string(event, "event_type")
            recipient, subject, content = render(event)
        except (KeyError, TypeError, ValueError, json.JSONDecodeError) as error:
            self.respond(400, {"error": str(error)})
            return

        state = claim_delivery(delivery_id, event_id, event_type, attempt)
        if state in ("completed", "processing"):
            self.respond(202, {"status": state})
            return
        try:
            provider_message_id = send_email(recipient, subject, content)
            finish_delivery(delivery_id, "completed", provider_message_id)
        except (OSError, smtplib.SMTPException) as error:
            finish_delivery(delivery_id, "failed", error=str(error))
            self.respond(503, {"error": "email provider unavailable"})
            return
        self.respond(202, {"status": "completed"})

    def respond(self, status, payload):
        body = json.dumps(payload).encode()
        self.send_response(status)
        self.send_header("Content-Type", "application/json")
        self.send_header("Content-Length", str(len(body)))
        self.end_headers()
        self.wfile.write(body)

    def log_message(self, message, *args):
        print(f"{self.address_string()} {message % args}", flush=True)


def required_string(value, name):
    result = value[name]
    if not isinstance(result, str) or not result:
        raise ValueError(f"{name} must be a non-empty string")
    return result


if __name__ == "__main__":
    migrate()
    address = os.getenv("LISTEN_ADDR", "0.0.0.0")
    port = int(os.getenv("PORT", "8080"))
    print(f"email sink listening on {address}:{port}", flush=True)
    ThreadingHTTPServer((address, port), Handler).serve_forever()
