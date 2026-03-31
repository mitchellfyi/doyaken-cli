#!/usr/bin/env python3
"""
Doyaken Guard Handler — evaluates markdown-based guard rules.

Reads guard files from:
  1. $DOYAKEN_DIR/hooks/guards/*.md  (built-in guards)
  2. .doyaken/guards/*.md            (project-specific guards)

Each guard is a markdown file with YAML frontmatter:

  ---
  name: guard-name
  enabled: true
  event: bash|file|commit
  pattern: regex-pattern
  action: warn|block
  ---

  Message body shown when triggered.

Exit codes:
  0 = no guard triggered (or warn only)
  2 = a blocking guard triggered

No external dependencies — stdlib only.
"""
import os
import re
import signal
import subprocess
import sys
import glob


def parse_frontmatter(text):
    """Parse simple YAML frontmatter without PyYAML. Handles flat key: value pairs.

    Limitations: only supports single-line scalar values (strings, booleans).
    Does not support nested objects, arrays, multiline strings, or anchors.
    This is intentional — guard files use a flat schema. See docs/guards.md.
    """
    result = {}
    for line in text.strip().splitlines():
        line = line.strip()
        if not line or line.startswith('#'):
            continue
        # Handle "key: value" pairs
        match = re.match(r'^([a-zA-Z_][\w_-]*)\s*:\s*(.*)', line)
        if match:
            key = match.group(1)
            val = match.group(2).strip()
            # Strip surrounding quotes (require at least 2 chars to avoid
            # corrupting a bare quote character like `key: "`)
            if len(val) >= 2 and (
                (val.startswith('"') and val.endswith('"')) or
                (val.startswith("'") and val.endswith("'"))
            ):
                val = val[1:-1]
            # Parse booleans (supports YAML-style yes/no as well as true/false)
            if val.lower() in ('true', 'yes'):
                val = True
            elif val.lower() in ('false', 'no'):
                val = False
            result[key] = val
    return result


def parse_guard(filepath):
    """Parse a guard markdown file with YAML frontmatter."""
    try:
        with open(filepath, 'r') as f:
            content = f.read()
    except (OSError, IOError):
        print(f"[guard] skipped {filepath}: cannot read file", file=sys.stderr)
        return None

    if not content.startswith('---'):
        print(f"[guard] skipped {filepath}: missing frontmatter", file=sys.stderr)
        return None

    parts = content.split('---', 2)
    if len(parts) < 3:
        print(f"[guard] skipped {filepath}: malformed frontmatter", file=sys.stderr)
        return None

    try:
        meta = parse_frontmatter(parts[1])
    except Exception as e:
        print(f"[guard] skipped {filepath}: parse error: {e}", file=sys.stderr)
        return None

    if not meta or not meta.get('enabled', True):
        return None

    meta['message'] = parts[2].strip()
    meta['source'] = filepath
    return meta


def load_guards(event_type):
    """Load all enabled guards for a given event type."""
    guards = []
    doyaken_dir = os.environ.get('DOYAKEN_DIR') or os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

    # Built-in guards
    builtin_dir = os.path.join(doyaken_dir, 'hooks', 'guards')
    if os.path.isdir(builtin_dir):
        for f in sorted(glob.glob(os.path.join(builtin_dir, '*.md'))):
            g = parse_guard(f)
            if g:
                if not g.get('event'):
                    print(f"[guard] Warning: guard {f} missing 'event' field, skipping", file=sys.stderr)
                elif g['event'] in (event_type, 'all'):
                    guards.append(g)

    # Project-specific guards — resolve project root via git toplevel so guards
    # are found regardless of which subdirectory the tool runs from.
    try:
        project_root = subprocess.check_output(
            ['git', 'rev-parse', '--show-toplevel'],
            text=True, stderr=subprocess.DEVNULL
        ).strip()
    except Exception:
        project_root = os.getcwd()
    project_dir = os.path.join(project_root, '.doyaken', 'guards')
    if os.path.isdir(project_dir):
        for f in sorted(glob.glob(os.path.join(project_dir, '*.md'))):
            g = parse_guard(f)
            if g:
                if not g.get('event'):
                    print(f"[guard] Warning: guard {f} missing 'event' field, skipping", file=sys.stderr)
                elif g['event'] in (event_type, 'all'):
                    guards.append(g)

    return guards


def _timeout_handler(signum, frame):
    """SIGALRM handler for ReDoS protection. Defined at module level to avoid
    creating a new function object per guard iteration."""
    raise TimeoutError()


def check_guards(guards, text):
    """Check text against all guards. Returns (warnings, blocks).

    Each guard's regex pattern is matched against the full text using re.search
    (not re.match — the pattern can appear anywhere). Matching is case-insensitive
    by default; set case_sensitive: true in frontmatter for exact-case matching.
    """
    warnings = []
    blocks = []

    for guard in guards:
        pattern = guard.get('pattern', '')
        name = guard.get('name', 'unnamed')
        if not pattern:
            print(f"[guard:{name}] skipped — no pattern defined", file=sys.stderr)
            continue

        try:
            flags = re.MULTILINE
            # Default: case-insensitive matching. Set `case_sensitive: true`
            # in frontmatter to require exact case. See docs/guards.md.
            if not guard.get('case_sensitive'):
                flags |= re.IGNORECASE
            compiled = re.compile(pattern, flags)
        except re.error as e:
            print(f"[guard:{name}] skipped — invalid regex: {e}", file=sys.stderr)
            continue

        # ReDoS protection: guard patterns come from .md files which could be
        # contributed by anyone in a repo. A 2-second alarm prevents pathological
        # backtracking from hanging the hook. When the alarm fires, the signal
        # handler raises TimeoutError in the main thread, interrupting re.search.
        # signal.alarm is Unix-only; Doyaken targets macOS/Linux exclusively.
        # See: https://docs.python.org/3/library/signal.html#signal.alarm
        _prev_handler = signal.signal(signal.SIGALRM, _timeout_handler)
        signal.alarm(2)
        try:
            matched = compiled.search(text)
        except TimeoutError:
            print(f"[guard:{name}] skipped — regex timed out (possible ReDoS)", file=sys.stderr)
            continue
        finally:
            signal.alarm(0)
            signal.signal(signal.SIGALRM, _prev_handler)

        if not matched:
            continue

        entry = {
            'name': name,
            'message': guard.get('message', 'Guard triggered.'),
            'action': guard.get('action', 'warn'),
        }

        if entry['action'] == 'block':
            blocks.append(entry)
        else:
            warnings.append(entry)

    return warnings, blocks


def main():
    # Flow: read tool input from env → determine event type → load matching
    # guards from built-in (hooks/guards/) and project (.doyaken/guards/) dirs
    # → check each guard's regex against the input → print warnings/blocks
    # → exit 2 if any blocking guard triggered, 0 otherwise.
    # See: docs/guards.md for full guard system documentation.
    tool_input = os.environ.get('CLAUDE_TOOL_USE_INPUT', '')

    # Determine event type from environment
    event_type = os.environ.get('DOYAKEN_GUARD_EVENT', 'bash')

    guards = load_guards(event_type)
    if not guards:
        sys.exit(0)

    # Build text to check against
    text = tool_input

    # For commit events, fetch committed files and message from git if not
    # already provided (post-commit-guard.sh sets CLAUDE_TOOL_USE_INPUT)
    if event_type == 'commit' and not text.strip():
        try:
            msg = subprocess.check_output(
                ['git', 'log', '-1', '--pretty=format:%s'], text=True, stderr=subprocess.DEVNULL
            ).strip()
            files = subprocess.check_output(
                ['git', 'diff-tree', '--no-commit-id', '--name-only', '-r', 'HEAD'],
                text=True, stderr=subprocess.DEVNULL
            ).strip()
            text = f"{files}\n{msg}"
        except Exception:
            pass

    warnings, blocks = check_guards(guards, text)

    # Print warnings
    for w in warnings:
        print(f"\n[guard:{w['name']}] WARNING")
        print(w['message'])

    # Print blocks
    for b in blocks:
        print(f"\n[guard:{b['name']}] BLOCKED")
        print(b['message'])

    # Exit 2 to block if any blocking guards triggered
    if blocks:
        sys.exit(2)

    sys.exit(0)


if __name__ == '__main__':
    main()
