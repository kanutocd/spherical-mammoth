# ADR-0002: Use Purposeful Polyglot Boundaries

- Status: Accepted

## Decision

Use Ruby/Rails for the core SaaS API, Go for the identity lifecycle bridge, Python for the transactional email sink, and TypeScript/React for the frontend.

## Rationale

The language choices match service responsibilities and demonstrate that Mammoth is not coupled to Ruby producers or consumers.

## Contract rule

All cross-language contracts are language-neutral and versioned using JSON Schema or OpenAPI.
