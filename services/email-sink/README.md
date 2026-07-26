# Transactional email sink

The sink accepts Mammoth row-level CDC events routed from
`public.domain_events`, extracts the application-owned semantic event,
deduplicates deliveries in SQLite, renders identity lifecycle messages, and
sends them through SMTP. The provisional delivery envelope remains accepted for
scenario compatibility. Mailpit is the default provider locally.

Set `DELIVERY_SECRET` to verify Mammoth's HMAC-SHA256 signature over
`<X-Mammoth-Timestamp>.<request body>`.
