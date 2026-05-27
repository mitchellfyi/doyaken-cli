# Dex Run Data

Dex writes local run data for provider-backed commands. Events are the
machine-readable timeline. Logs and artifacts are the human-readable debugging
and evidence trail.

## Storage

Each run gets a stable ID and a directory under:

```text
~/.dex/runs/<run_id>/
  spec.json
  events.jsonl
  logs.txt
  summary.json
  artifacts/
    manifest.json
    run-summary.md
    ...
```

`dx`, `dx init`, and `dx sync` print the current run ID near startup. Main
lifecycle runs also show it in the phase header.

Run data is local only. Dex does not sync events, logs, or artifacts to a
service. Event, log, and artifact writes are treated as non-fatal after the run
directory has been prepared.

## Mental Model

- Events are small structured state changes used by future timelines, reports,
  and notifications.
- Logs are timestamped text for a person debugging a run.
- Artifacts are files produced during a run, with manifest metadata so a UI can
  display them later.

Do not model every log line as an event. Emit events for state changes and
write detailed output to `logs.txt`.

## Event Schema

`events.jsonl` is append-only. Each line is one JSON object:

| Field | Type | Notes |
|-------|------|-------|
| `id` | string | Event ID, unique inside the journal |
| `run_id` | string | Stable run ID, also used as the directory name |
| `sequence` | number | Monotonic sequence for this run |
| `type` | string | Dotted event name such as `run.started` |
| `company_slug` | string | Owner parsed from `origin`, when available |
| `project_slug` | string | Repo name parsed from `origin` or the directory |
| `repo` | string | `owner/repo` when available, otherwise repo directory name |
| `phase` | string or null | Lifecycle phase number when the event belongs to a phase |
| `severity` | string | `info`, `warn`, or `error` |
| `message` | string | Short human-readable summary |
| `data` | object | Event-specific structured payload |
| `created_at` | string | UTC timestamp in ISO-8601 form |

Current lifecycle event types include:

- `run.started`
- `run.completed`
- `run.failed`
- `run.blocked`
- `phase.started`
- `phase.completed`
- `phase.failed`
- `artifact.created`
- `plan.created` and other event types emitted by future lifecycle helpers

## Logs

`logs.txt` stores timestamped human-readable lines. Dex writes lifecycle
messages there and tees filtered provider progress from `dx init` and `dx sync`
when provider analysis runs.

Dex applies basic redaction before writing to logs:

- token, secret, password, auth, and API-key assignments
- common GitHub, OpenAI, Slack, and bearer/basic auth token forms

This is a guardrail, not a full secret scanner. Logs stay local and must not be
committed to the product repo.

## Artifacts

`artifacts/manifest.json` lists local artifacts:

```json
{
  "schema_version": 1,
  "artifacts": [
    {
      "id": "art_abc123",
      "type": "run_summary",
      "path": "run-summary.md",
      "title": "Run summary",
      "size_bytes": 312,
      "sha256": "...",
      "metadata": {
        "status": "completed"
      },
      "created_at": "2026-05-27T12:34:56Z",
      "updated_at": "2026-05-27T12:34:56Z"
    }
  ]
}
```

Artifact paths are relative to `artifacts/`; absolute paths and `..` segments
are rejected. Registering an artifact emits `artifact.created`.

`summary.json` is the machine-readable final run summary. Dex also writes
`artifacts/run-summary.md` and records it in the manifest when summaries are
updated.

## Reading Data

Inspect the latest run manually:

```bash
run_id=$(ls -t ~/.dex/runs | head -1)
tail -n 20 "$HOME/.dex/runs/$run_id/events.jsonl"
tail -n 20 "$HOME/.dex/runs/$run_id/logs.txt"
python3 -m json.tool "$HOME/.dex/runs/$run_id/artifacts/manifest.json"
```

Pretty-print a journal with Python:

```bash
python3 -m json.tool ~/.dex/runs/<run_id>/summary.json
python3 - ~/.dex/runs/<run_id>/events.jsonl <<'PY'
import json
import sys

for line in open(sys.argv[1], encoding="utf-8"):
    event = json.loads(line)
    print(event["sequence"], event["type"], event["phase"], event["message"])
PY
```
