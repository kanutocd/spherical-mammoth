DO $$
BEGIN
  IF NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'mammoth') THEN
    CREATE ROLE mammoth WITH LOGIN REPLICATION PASSWORD 'development-only';
  END IF;
END
$$;

CREATE EXTENSION IF NOT EXISTS pgcrypto;

CREATE TABLE IF NOT EXISTS signup_requests (
  id uuid PRIMARY KEY,
  identity_id text NOT NULL UNIQUE,
  email text NOT NULL,
  display_name text,
  status text NOT NULL CHECK (status IN ('verification_requested', 'completed')),
  created_at timestamptz NOT NULL DEFAULT now(),
  completed_at timestamptz
);

CREATE TABLE IF NOT EXISTS accounts (
  id uuid PRIMARY KEY,
  identity_id text NOT NULL UNIQUE,
  email text NOT NULL,
  display_name text,
  created_at timestamptz NOT NULL DEFAULT now()
);

CREATE TABLE IF NOT EXISTS domain_events (
  event_id uuid PRIMARY KEY,
  event_type text NOT NULL,
  aggregate_id uuid NOT NULL,
  occurred_at timestamptz NOT NULL DEFAULT now(),
  data jsonb NOT NULL,
  CHECK (jsonb_typeof(data) = 'object')
);

GRANT SELECT ON TABLE domain_events TO mammoth;

DO $$
BEGIN
  IF NOT EXISTS (
    SELECT 1 FROM pg_publication WHERE pubname = 'spherical_mammoth_publication'
  ) THEN
    CREATE PUBLICATION spherical_mammoth_publication FOR TABLE domain_events;
  END IF;
END
$$;
