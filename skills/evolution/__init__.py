"""Evolution Protocol — Self-modification, subagent spawning, and autonomous learning for AI Beings."""

from .config import EvolutionConfig
from .evolution_mixin import EvolutionMixin
from .ws_server import WSServerMixin
from .evolve import evolve, propose_change, review_evolution
from .spawn import spawn_agent, get_spawn_result, register_tool_set, register_tool

__all__ = [
    "EvolutionConfig",
    "EvolutionMixin",
    "WSServerMixin",
    "evolve",
    "propose_change",
    "review_evolution",
    "spawn_agent",
    "get_spawn_result",
    "register_tool_set",
    "register_tool",
]
