"""Self-modification tools — a Being can improve its own code.

Safety: git worktree isolation, test gate, PR-based review, SOUL.md readonly.

This is a Being-agnostic extraction from the Evolution Protocol.
Each Being should configure its own repo root, allowed scopes, and readonly files
via EvolutionConfig.
"""

import json
import logging
import re
import subprocess
import time
from pathlib import Path

from .config import EvolutionConfig

log = logging.getLogger("beings.evolution")


def _validate_scope(scope: str, config: EvolutionConfig) -> bool:
    """Check if scope is within allowed directories."""
    return any(scope.startswith(s) or scope == s for s in config.allowed_scopes)


def _slugify(text: str) -> str:
    """Convert text to branch-safe slug."""
    return re.sub(r'[^a-z0-9]+', '-', text.lower().strip())[:40].strip('-')


def evolve(
    goal: str,
    repo_root: Path,
    scope: str = "agent/",
    max_budget_usd: float = 0.50,
    run_tests: bool = True,
    config: EvolutionConfig | None = None,
    test_command: list[str] | None = None,
    being_name: str = "Being",
) -> str:
    """Improve the Being's own code. Runs Claude Code in a git worktree, creates a PR.

    Args:
        goal: What to improve. Be specific. Example: "Add docstrings to heartbeat.py"
        repo_root: Path to the Being's repository root.
        scope: Directory to focus on (must be in allowed scope). Default: "agent/"
        max_budget_usd: Maximum spend for this evolution (default $0.50).
        run_tests: Whether to run pytest before creating PR (default True).
        config: EvolutionConfig instance. Uses defaults if None.
        test_command: Custom test command. Defaults to ["python", "-m", "pytest", "tests/", "-x", "--tb=short", "-q"].
        being_name: Name of the Being (for commit messages and PR descriptions).

    Returns:
        PR URL if successful, or error description.
    """
    if config is None:
        config = EvolutionConfig()

    if not _validate_scope(scope, config):
        return f"ERROR: Scope '{scope}' not allowed. Allowed: {config.allowed_scopes}"

    ts = int(time.time())
    slug = _slugify(goal)
    branch = f"evolve/{ts}-{slug}"
    worktree_path = Path(f"/tmp/beings-evolve-{ts}")

    try:
        # 1. Create git worktree
        result = subprocess.run(
            ["git", "worktree", "add", "-b", branch, str(worktree_path)],
            cwd=str(repo_root), capture_output=True, text=True, timeout=30,
        )
        if result.returncode != 0:
            return f"ERROR: Failed to create worktree: {result.stderr[:200]}"

        log.info(f"Evolution: worktree at {worktree_path}, branch {branch}")

        # 2. Run Claude Code CLI in the worktree
        prompt = (
            f"You are improving {being_name}'s code.\n\n"
            f"GOAL: {goal}\n"
            f"SCOPE: Only modify files under '{scope}'\n\n"
            f"RULES:\n"
            f"- NEVER modify these files: {', '.join(config.readonly_files)}\n"
            f"- Only modify files under: {', '.join(config.allowed_scopes)}\n"
            f"- Write clean, tested code\n"
            f"- Follow existing patterns in the codebase\n"
        )

        claude_result = subprocess.run(
            [
                str(config.claude_bin), "--print",
                "--output-format", "json",
                "--bare",
                "--dangerously-skip-permissions",
                "--max-budget-usd", str(max_budget_usd),
                "--tools", "Edit,Write,Bash,Read,Glob,Grep",
                "-p", prompt,
            ],
            cwd=str(worktree_path),
            capture_output=True, text=True, timeout=300,
        )

        if claude_result.returncode != 0:
            return f"ERROR: Claude Code failed: {claude_result.stderr[:300]}"

        # 3. Check for readonly file violations
        diff_result = subprocess.run(
            ["git", "diff", "--name-only"],
            cwd=str(worktree_path), capture_output=True, text=True,
        )
        changed_files = diff_result.stdout.strip().split("\n") if diff_result.stdout.strip() else []

        # Also check untracked files
        untracked = subprocess.run(
            ["git", "ls-files", "--others", "--exclude-standard"],
            cwd=str(worktree_path), capture_output=True, text=True,
        )
        if untracked.stdout.strip():
            changed_files.extend(untracked.stdout.strip().split("\n"))

        for f in changed_files:
            for readonly in config.readonly_files:
                if f.startswith(readonly) or f == readonly.rstrip('/'):
                    return f"ABORT: Evolution tried to modify readonly file: {f}"

        if not changed_files:
            return "No changes made — nothing to evolve."

        # 4. Run tests if required
        if run_tests:
            cmd = test_command or ["python", "-m", "pytest", "tests/", "-x", "--tb=short", "-q"]
            test_result = subprocess.run(
                cmd,
                cwd=str(worktree_path), capture_output=True, text=True, timeout=120,
            )
            if test_result.returncode != 0:
                return f"TESTS FAILED — PR not created.\n{test_result.stdout[-500:]}"

        # 5. Commit changes
        subprocess.run(["git", "add", "-A"], cwd=str(worktree_path), capture_output=True)
        subprocess.run(
            ["git", "commit", "-m", f"evolve: {goal[:70]}\n\nSelf-evolution by {being_name}.\nScope: {scope}"],
            cwd=str(worktree_path), capture_output=True, text=True,
        )

        # 6. Push branch
        push_result = subprocess.run(
            ["git", "push", "origin", branch],
            cwd=str(worktree_path), capture_output=True, text=True, timeout=60,
        )
        if push_result.returncode != 0:
            return f"ERROR: Push failed: {push_result.stderr[:200]}"

        # 7. Create PR
        pr_result = subprocess.run(
            ["gh", "pr", "create",
             "--title", f"evolve: {goal[:60]}",
             "--body", (
                 f"## Self-Evolution\n\n"
                 f"**Goal:** {goal}\n"
                 f"**Scope:** {scope}\n"
                 f"**Budget:** ${max_budget_usd}\n"
                 f"**Being:** {being_name}\n"
                 f"**Files:** {', '.join(changed_files[:10])}\n\n"
                 f"Auto-generated by {being_name}'s Evolution Protocol"
             ),
             "--base", "main",
             "--head", branch,
             "--label", "evolution"],
            cwd=str(worktree_path), capture_output=True, text=True, timeout=30,
        )

        pr_url = pr_result.stdout.strip() if pr_result.returncode == 0 else "PR creation failed"

        log.info(f"Evolution complete: {pr_url}")
        return f"Evolution PR created: {pr_url}\nFiles changed: {', '.join(changed_files[:5])}"

    except subprocess.TimeoutExpired:
        return "ERROR: Evolution timed out (5 min limit)"
    except Exception as e:
        return f"ERROR: {type(e).__name__}: {e}"
    finally:
        # Always clean up worktree
        try:
            subprocess.run(
                ["git", "worktree", "remove", "--force", str(worktree_path)],
                cwd=str(repo_root), capture_output=True, timeout=30,
            )
        except Exception:
            pass


def propose_change(description: str, files: str = "", being_name: str = "Being") -> str:
    """Propose a code change without executing it. For review before committing.

    Use when you have an idea but want to think more or get approval first.

    Args:
        description: What you want to change and why.
        files: Comma-separated list of files that would be affected.
        being_name: Name of the Being proposing the change.
    """
    log.info(f"Evolution proposed by {being_name}: {description[:100]}")
    return f"Proposal logged: {description}"


def review_evolution(pr_number: int, repo_root: Path) -> str:
    """Check the status of a previously created evolution PR.

    Args:
        pr_number: GitHub PR number to check.
        repo_root: Path to the Being's repository root.
    """
    try:
        result = subprocess.run(
            ["gh", "pr", "view", str(pr_number), "--json", "state,title,reviews,statusCheckRollup"],
            cwd=str(repo_root), capture_output=True, text=True, timeout=15,
        )
        if result.returncode == 0:
            return result.stdout[:1000]
        return f"ERROR: {result.stderr[:200]}"
    except Exception as e:
        return f"ERROR: {e}"
