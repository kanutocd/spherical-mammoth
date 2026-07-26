# Delivery compatibility contracts

The schemas in this directory describe payloads accepted by Spherical Mammoth
sinks. They are consumer-owned compatibility contracts, not canonical Mammoth
transport schemas.

`email-sink-mammoth-event.v1.schema.json` represents the row-level webhook
subset consumed from Mammoth v1.5.1. Its compatibility fixture is based on that
release's documented serializer contract and is exercised by
`scripts/check-scaffold`.

Mammoth currently owns the canonical human-readable payload contract in its
`docs/WEBHOOK-PAYLOADS.md`. When Mammoth publishes versioned machine-readable
webhook schemas, replace this local representation with a pinned upstream
artifact and record its release provenance and checksum.
