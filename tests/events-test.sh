#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
TMP_DIR="$(mktemp -d "${TMPDIR:-/tmp}/dex-events-test.XXXXXX")"

cleanup() {
  rm -rf "$TMP_DIR"
}
trap cleanup EXIT

export HOME="$TMP_DIR/home"
export DEX_DIR="$ROOT"
export DX_STATE_DIR="$TMP_DIR/state"
export DX_LOOP_DIR="$TMP_DIR/loops"
export DX_ARTIFACT_DIR="$TMP_DIR/artifacts"
export DX_TOOL_DIR="$TMP_DIR/tools"
export DX_RUN_ROOT="$TMP_DIR/runs"

# shellcheck disable=SC1091
source "$ROOT/lib/common.sh"

assert_file() {
  [[ -f "$1" ]] || {
    printf 'missing file: %s\n' "$1" >&2
    exit 1
  }
}

assert_dir() {
  [[ -d "$1" ]] || {
    printf 'missing dir: %s\n' "$1" >&2
    exit 1
  }
}

run_a="$(dx_run_id)"
run_b="$(dx_run_id)"
[[ "$run_a" == run_* ]] || { printf 'run id missing prefix: %s\n' "$run_a" >&2; exit 1; }
[[ "$run_a" != "$run_b" ]] || { printf 'run ids are not unique\n' >&2; exit 1; }
dx_run_validate_id "$run_a"

session_id="test-session"
run_id="$(dx_run_prepare "$session_id" "$ROOT" "test" "events-test" "issue-46" "dx test")"
[[ -n "$run_id" ]] || { printf 'run id was empty\n' >&2; exit 1; }
[[ "$(dx_run_read_for_session "$session_id")" == "$run_id" ]]

run_dir="$(dx_run_dir "$run_id")"
assert_dir "$run_dir"
assert_dir "$(dx_run_artifacts_dir "$run_id")"
assert_file "$(dx_run_spec_file "$run_id")"
assert_file "$(dx_run_logs_file "$run_id")"
assert_file "$(dx_run_artifact_manifest_file "$run_id")"

dx_run_maybe_emit_started "$run_id" "Test run started" '{"command":"test"}'
dx_event_maybe_emit_phase_started "$run_id" "1" "Plan" "test"
dx_event_emit "$run_id" "plan.created" "info" "Plan created" "1" '{"items":2}'
dx_event_emit "$run_id" "phase.completed" "info" "Phase 1 completed" "1" '{"duration_s":3,"iterations":1}'
artifact_file="$(dx_run_artifact_file "$run_id" "reports/test-output.txt")"
mkdir -p "$(dirname "$artifact_file")"
printf 'test output\n' > "$artifact_file"
dx_run_register_artifact "$run_id" "test_output" "reports/test-output.txt" "Test output" '{"command":"test"}'
dx_run_log_append "$run_id" "info" "test" "Saved token=supersecret and sk-12345678901234567890"
printf 'provider github_pat_12345678901234567890 secret=plain\n' | dx_run_log_tee "$run_id" "provider" > "$TMP_DIR/tee-output.txt"
dx_run_write_summary "$run_id" "completed" "events test completed"

assert_file "$(dx_run_events_file "$run_id")"
assert_file "$(dx_run_summary_file "$run_id")"
assert_file "$(dx_run_artifact_manifest_file "$run_id")"
assert_file "$(dx_run_artifact_file "$run_id" "run-summary.md")"

python3 - "$run_dir" "$run_id" "$ROOT" <<'PY'
import json
import sys
from pathlib import Path

run_dir = Path(sys.argv[1])
run_id = sys.argv[2]
repo_root = sys.argv[3]

spec = json.loads((run_dir / "spec.json").read_text(encoding="utf-8"))
assert spec["schema_version"] == 1
assert spec["run_id"] == run_id
assert spec["session_id"] == "test-session"
assert spec["command"] == "dx test"
assert spec["repo_path"] == repo_root

events = [
    json.loads(line)
    for line in (run_dir / "events.jsonl").read_text(encoding="utf-8").splitlines()
    if line.strip()
]
assert [event["sequence"] for event in events] == [1, 2, 3, 4, 5, 6]
assert [event["type"] for event in events] == [
    "run.started",
    "phase.started",
    "plan.created",
    "phase.completed",
    "artifact.created",
    "artifact.created",
]
for event in events:
    assert event["id"].startswith("evt_")
    assert event["run_id"] == run_id
    assert isinstance(event["data"], dict)
    assert event["created_at"].endswith("Z")
    for field in ("company_slug", "project_slug", "repo", "phase", "severity", "message"):
        assert field in event

assert events[1]["phase"] == "1"
assert events[2]["data"]["items"] == 2
assert events[4]["data"]["path"] == "reports/test-output.txt"
assert events[5]["data"]["path"] == "run-summary.md"

summary = json.loads((run_dir / "summary.json").read_text(encoding="utf-8"))
assert summary["run_id"] == run_id
assert summary["status"] == "completed"
assert summary["last_sequence"] == 6

manifest = json.loads((run_dir / "artifacts" / "manifest.json").read_text(encoding="utf-8"))
artifacts = manifest["artifacts"]
assert [artifact["path"] for artifact in artifacts] == ["reports/test-output.txt", "run-summary.md"]
assert artifacts[0]["type"] == "test_output"
assert artifacts[0]["size_bytes"] == len("test output\n")
assert artifacts[0]["metadata"]["command"] == "test"
assert artifacts[1]["type"] == "run_summary"

log_text = (run_dir / "logs.txt").read_text(encoding="utf-8")
assert "[test]" in log_text
assert "[provider]" in log_text
assert "token=[REDACTED]" in log_text
assert "secret=[REDACTED]" in log_text
assert "supersecret" not in log_text
assert "github_pat_12345678901234567890" not in log_text
assert "sk-12345678901234567890" not in log_text

tee_text = (run_dir.parent.parent / "tee-output.txt").read_text(encoding="utf-8")
assert "github_pat_12345678901234567890" in tee_text
PY

printf 'events tests passed\n'
