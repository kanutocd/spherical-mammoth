# Initial Service-Level Objectives

These objectives become enforceable after the first vertical slice exists.

- Signup lifecycle event capture success: 99.9% over a rolling 30-day window.
- No acknowledged committed signup event is permanently lost.
- Local Mailpit delivery P95: under 5 seconds from source commit.
- Duplicate effective email delivery rate: 0 for events with a stable idempotency key.
- Mammoth checkpoint recovery: resume without operator data repair after an expected process restart.
