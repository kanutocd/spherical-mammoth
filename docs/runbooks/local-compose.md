# Runbook: Local Compose

The Compose stack is the default developer and demonstration environment.

Planned command:

```bash
docker compose --file deployment/compose/compose.yaml up --build
```

The initial scaffold defines service names, networks, volumes, health dependencies, and configuration mounts. Service images are placeholders until Milestone 1 implementations exist.
