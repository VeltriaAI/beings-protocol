"""Subagent spawning — create temporary ADK agents for focused tasks.

The Being can spawn short-lived agents with restricted tool sets.
Tool sets are fully configurable — register your own via register_tool_set().

This is a Being-agnostic extraction from the Evolution Protocol.
"""

import asyncio
import logging
import threading
import time
from pathlib import Path

from .config import EvolutionConfig

log = logging.getLogger("beings.evolution")

# Registry of completed spawn results
_spawn_results: dict[str, dict] = {}
_spawn_lock = threading.Lock()

# Module-level event loop for spawned agents (separate from Being's loop)
_spawn_loop = asyncio.new_event_loop()
_spawn_thread = threading.Thread(target=_spawn_loop.run_forever, daemon=True)
_spawn_thread.start()

# Configurable tool sets — map name to list of tool function names
# Beings register their own tool sets via register_tool_set()
_TOOL_SETS: dict[str, list[str]] = {
    "introspection": ["read_file", "write_file"],
}

# Tool function registry — map function name to callable
_TOOL_REGISTRY: dict[str, callable] = {}


def register_tool_set(name: str, tool_names: list[str]):
    """Register a named tool set for spawned agents.

    Args:
        name: Name of the tool set (e.g., "research", "analysis").
        tool_names: List of tool function names available to spawned agents.
    """
    _TOOL_SETS[name] = tool_names
    log.info(f"Registered tool set '{name}': {tool_names}")


def register_tool(name: str, func: callable):
    """Register a tool function that can be used by spawned agents.

    Args:
        name: Function name (must match names used in tool sets).
        func: The callable tool function.
    """
    _TOOL_REGISTRY[name] = func


def _resolve_tools(tool_set: str) -> list:
    """Resolve tool set name to actual FunctionTool instances."""
    from google.adk.tools import FunctionTool

    names = _TOOL_SETS.get(tool_set, [])
    tools = []
    for n in names:
        if n in _TOOL_REGISTRY:
            tools.append(FunctionTool(func=_TOOL_REGISTRY[n]))
        else:
            log.warning(f"Tool '{n}' not found in registry — skipping")
    return tools


async def _run_spawn(
    task: str,
    tool_set: str,
    spawn_id: str,
    model_config: dict | None = None,
    being_name: str = "Being",
):
    """Run a spawned agent asynchronously.

    Args:
        task: The task for the spawned agent.
        tool_set: Which tool set to use.
        spawn_id: Unique identifier for this spawn.
        model_config: Dict with 'model', 'api_key', 'api_base' keys for LLM.
        being_name: Name of the parent Being.
    """
    from google.adk.agents import LlmAgent
    from google.adk.apps.app import App
    from google.adk.models.lite_llm import LiteLlm
    from google.adk.runners import Runner
    from google.adk.sessions import InMemorySessionService
    from google.genai import types

    if not model_config:
        raise ValueError("model_config is required for spawning agents")

    model = LiteLlm(
        model=model_config["model"],
        api_key=model_config.get("api_key", ""),
        api_base=model_config.get("api_base", ""),
    )

    tools = _resolve_tools(tool_set)
    agent = LlmAgent(
        name=f"spawn_{spawn_id}",
        model=model,
        instruction=(
            f"You are a temporary agent spawned by {being_name} for a specific task. "
            f"Complete the task and return results concisely.\n\n"
            f"Available tool set: {tool_set}"
        ),
        tools=tools,
        description=f"Temporary {tool_set} agent",
    )

    app_name = f"spawn_{spawn_id}"
    app = App(name=app_name, root_agent=agent)
    session_service = InMemorySessionService()
    runner = Runner(app=app, session_service=session_service)
    session = await session_service.create_session(app_name=app_name, user_id="spawn")

    message = types.Content(role="user", parts=[types.Part(text=task)])
    result = ""
    async for event in runner.run_async(
        session_id=session.id, user_id="spawn", new_message=message
    ):
        if event.content and event.content.parts:
            for part in event.content.parts:
                if part.text:
                    result += part.text

    return result


def spawn_agent(
    task: str,
    tool_set: str = "introspection",
    timeout_seconds: int = 120,
    model_config: dict | None = None,
    being_name: str = "Being",
    config: EvolutionConfig | None = None,
) -> str:
    """Spawn a temporary agent to work on a specific task.

    The agent gets a restricted set of tools and runs independently.

    Args:
        task: What the spawned agent should do. Be specific.
        tool_set: Which tools to give it. Use register_tool_set() to add custom sets.
        timeout_seconds: Max time before giving up (default 120s).
        model_config: Dict with 'model', 'api_key', 'api_base' for the LLM.
        being_name: Name of the parent Being.
        config: EvolutionConfig for limits. Uses defaults if None.

    Returns:
        The spawned agent's response.
    """
    if config is None:
        config = EvolutionConfig()

    if tool_set not in _TOOL_SETS:
        return f"ERROR: Invalid tool_set '{tool_set}'. Available: {list(_TOOL_SETS.keys())}"

    # Limit concurrent spawns
    with _spawn_lock:
        active = sum(1 for v in _spawn_results.values() if v.get("status") == "running")
        if active >= config.max_concurrent_spawns:
            return f"ERROR: Too many active spawns (max {config.max_concurrent_spawns}). Wait for one to finish."

    spawn_id = str(int(time.time()))[-6:]
    log.info(f"Spawning {tool_set} agent [{spawn_id}]: {task[:80]}")

    with _spawn_lock:
        _spawn_results[spawn_id] = {"status": "running", "task": task, "started": time.time()}

    try:
        future = asyncio.run_coroutine_threadsafe(
            _run_spawn(task, tool_set, spawn_id, model_config, being_name), _spawn_loop
        )
        result = future.result(timeout=timeout_seconds)

        with _spawn_lock:
            _spawn_results[spawn_id] = {"status": "done", "result": result, "finished": time.time()}

        log.info(f"Spawn [{spawn_id}] complete: {result[:200]}")

        # Prune old results (keep last 10)
        with _spawn_lock:
            if len(_spawn_results) > 10:
                oldest = sorted(_spawn_results.keys())[:-10]
                for k in oldest:
                    del _spawn_results[k]

        return result

    except TimeoutError:
        with _spawn_lock:
            _spawn_results[spawn_id] = {"status": "timeout", "task": task}
        return f"Spawn timed out after {timeout_seconds}s. ID: {spawn_id}"
    except Exception as e:
        with _spawn_lock:
            _spawn_results[spawn_id] = {"status": "error", "error": str(e)}
        log.error(f"Spawn [{spawn_id}] error: {e}")
        return f"Spawn error: {type(e).__name__}: {e}"


def get_spawn_result(spawn_id: str) -> str:
    """Get the result of a previously spawned agent.

    Args:
        spawn_id: The ID from a previous spawn_agent() call.

    Returns:
        The result if complete, or status if still running.
    """
    with _spawn_lock:
        entry = _spawn_results.get(spawn_id)
    if not entry:
        return f"No spawn found with ID: {spawn_id}"
    if entry["status"] == "running":
        elapsed = time.time() - entry.get("started", 0)
        return f"Still running ({elapsed:.0f}s elapsed). Task: {entry.get('task', '?')[:80]}"
    if entry["status"] == "done":
        return entry.get("result", "No result")
    return f"Status: {entry['status']}. {entry.get('error', '')}"
