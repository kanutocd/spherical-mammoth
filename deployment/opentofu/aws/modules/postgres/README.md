# PostgreSQL module

Creates an encrypted private RDS PostgreSQL instance with managed master
credentials, backups, logs, and logical replication parameters required by
Mammoth. A separate least-privilege replication role must be bootstrapped after
creation.
