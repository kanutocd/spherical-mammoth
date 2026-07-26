# Transactional email sink

The sink validates Mammoth HTTP envelopes, deduplicates deliveries in SQLite,
renders identity lifecycle messages, and sends them through SMTP. Mailpit is the
default provider in local environments.

Set `DELIVERY_SECRET` to require an HMAC-SHA256 value in the
`X-Mammoth-Signature` request header.
