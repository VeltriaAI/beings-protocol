"""Evolution configuration — standalone dataclass with safe defaults.

All evolution features are disabled by default. Beings must opt-in explicitly.
"""

from dataclasses import dataclass, field
from pathlib import Path


@dataclass
class EvolutionConfig:
    """Configuration for the Evolution Protocol."""

    # Master switch — evolution is opt-in
    enabled: bool = False

    # How often to trigger reflection (e.g., every N cycles/events)
    reflect_every_n: int = 5

    # Auto-evolution: if True, high-confidence patterns can trigger evolve() automatically
    auto_evolve: bool = False

    # Rate limits
    max_evolve_per_day: int = 2
    max_budget_per_evolve_usd: float = 0.50

    # Safety
    require_tests: bool = True

    # Files that must NEVER be modified
    readonly_files: set = field(default_factory=lambda: {
        ".beings/SOUL.md",
        ".env",
        ".git/",
    })

    # Directories the Being CAN modify (override per-Being)
    allowed_scopes: set = field(default_factory=lambda: {
        "agent/",
        "tests/",
        "docs/",
        ".beings/MEMORY.md",
        ".beings/GOALS.md",
        ".beings/AUTONOMY.md",
    })

    # Claude Code CLI path
    claude_bin: Path = field(default_factory=lambda: Path("~/.local/bin/claude").expanduser())

    # WebSocket server
    ws_port: int = 7779
    ws_host: str = "localhost"

    # Subagent limits
    max_concurrent_spawns: int = 3

    # Thinking/log file for pattern detection
    thinking_file: Path = field(default_factory=lambda: Path("/tmp/beings-evolution-thinking.log"))
