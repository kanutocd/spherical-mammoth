# Transactional email sink

The sink accepts Mammoth row-level CDC events routed from
`public.domain_events`, extracts the application-owned semantic event,
deduplicates deliveries in SQLite, renders identity lifecycle messages, and
sends them through SMTP. Mailpit is the default provider locally.

`contracts/delivery/email-sink-mammoth-event.v1.schema.json` defines the subset
of the Mammoth v1.5.3 webhook event contract accepted by this sink. It is a
consumer compatibility schema, not an upstream Mammoth-owned transport schema.

Set `DELIVERY_SECRET` to verify Mammoth's HMAC-SHA256 signature over
`<X-Mammoth-Timestamp>.<request body>`.
