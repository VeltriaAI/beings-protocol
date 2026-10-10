#!/usr/bin/env python3
"""team-fence.py: PreToolUse hook for teammate-lane runs; refuses tool calls that touch the owner's private paths.
   team-fence.py --settings   print the claude --settings JSON (this hook + auto memory off) used by being-handle/being-job"""
import json, os, re, sys

KIT = os.path.dirname(os.path.realpath(__file__))
H = r"(?:~|\$\{?HOME\}?|/home/[^/\s'\"]+|/Users/[^/\s'\"]+|/root)"
ENV_FILE = r"(?<![\w.-])\.env(?![\w-])(?!\.example)"
# Extra denied path fragments, comma-separated regexes (e.g. a private notes dir): BEING_FENCE_DENY in the kit .env.
EXTRA = [p for p in os.environ.get("BEING_FENCE_DENY", "").split(",") if p.strip()]
DENY = [
    (r"\.beings-local", "private owner files"),
    (H + r"/\.(?:config|ssh|aws|azure|kube|gnupg|docker|netrc|git-credentials|password-store)\b", "credentials"),
    (H + r"/\.claude(?:/projects|\.json)", "other sessions and auto memory"),
    (H + r"/\.codex/(?:sessions|archived_sessions|session_index|auth|history)", "other sessions"),
    # Sourcing the kit .env to send is fine; reading or copying any .env is not.
    (r"\b(?:cat|head|tail|less|more|grep|rg|sed|awk|strings|base64|xxd|od|cp|mv|scp|curl|python3?|node|env)\b[^|;&\n]*" + ENV_FILE, "credentials"),
    (r"teams-kit/state/(?!jobs/)", "kit state"),
    (r"\b(?:comms\.jsonl|owner-inbox|owner-watermark|token-cache[\w-]*|handler\.key|grants/|handler\.log)\b", "kit state"),
    (r"\b(?:owner-read|owner-mail|draft-for-owner|approve\.mjs|scope\.mjs)\b", "owner tools"),
    (r"/proc/[\w$]+/environ", "process environment"),
] + [(p.strip(), "private (BEING_FENCE_DENY)") for p in EXTRA]
JOB = re.compile(r"jobs/([0-9]{4}-[0-9]{6}-[\w-]+?)(?:\.result\.md|\.events\.jsonl|\.log|\.json)\b")

def lane_of(job_id):
    state = os.environ.get("BEING_STATE_DIR") or os.path.join(KIT, "state")
    try: s = json.load(open(os.path.join(state, "jobs", job_id + ".json"))).get("scope") or ""
    except (OSError, ValueError): return None
    return "team:" + s[6:].split(",")[0] if s.startswith("chats:") and s[6:] else "owner"

def settings():
    hook = {"type": "command", "command": "python3 " + json.dumps(os.path.realpath(__file__))}
    return json.dumps({"autoMemoryEnabled": False, "hooks": {"PreToolUse": [{"matcher": "*", "hooks": [hook]}]}})

def check(ev):
    """Reason string if the tool call must be refused, else None."""
    blob = json.dumps(ev.get("tool_input", {}), ensure_ascii=False).replace("\\/", "/")
    if ev.get("tool_name") in ("Read", "Edit", "Write", "Grep", "Glob", "NotebookEdit") and re.search(ENV_FILE, blob):
        return "credentials"
    for pat, what in DENY:
        if re.search(pat, blob): return what
    for jid in JOB.findall(blob):
        if lane_of(jid) != os.environ.get("BEING_LANE", ""): return f"job {jid} belongs to another conversation"
    return None

if __name__ == "__main__":
    if sys.argv[1:] == ["--settings"]: print(settings()); sys.exit(0)
    try: why = check(json.load(sys.stdin))
    except ValueError: why = "unreadable tool call"
    if why:
        print(f"team-fence: blocked ({why}). Teammate runs may not open the owner's private files, other conversations, "
              "credentials or owner tools. Answer from this chat and the project files.", file=sys.stderr)
        sys.exit(2)
