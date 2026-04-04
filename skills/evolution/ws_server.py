"""WebSocket server mixin — real-time command/response channel for Beings.

Provides bidirectional WebSocket communication on a configurable port.

Protocol:
  Client sends: {"type": "command", "id": "unique-id", "command": "talk", "args": {"message": "hello"}}
  Server responds: {"type": "response", "id": "unique-id", "result": "..."}
  Server pushes: {"type": "event", "event": "track_change", "data": {...}}

This is a Being-agnostic extraction from the Evolution Protocol.
"""

import asyncio
import json
import logging
import time

import websockets
from websockets.asyncio.server import serve

from .config import EvolutionConfig

log = logging.getLogger("beings.evolution")


class WSServerMixin:
    """WebSocket server mixin for real-time client communication.

    Requirements on the host class:
    - self._loop: asyncio event loop
    - self._handle_command(cmd, args, msg_id): method to handle sync commands

    Optional:
    - self._handle_ws_talk(message, readonly): async method for conversational commands
    """

    def _start_ws_server(self, config: EvolutionConfig | None = None):
        """Start WebSocket server on the Being's event loop.

        Args:
            config: EvolutionConfig with ws_host and ws_port. Uses defaults if None.
        """
        if config is None:
            config = EvolutionConfig()

        self._ws_clients: set = set()
        self._ws_config = config
        asyncio.run_coroutine_threadsafe(self._ws_serve(config), self._loop)
        log.info(f"WebSocket server starting on ws://{config.ws_host}:{config.ws_port}")

    async def _ws_serve(self, config: EvolutionConfig):
        """Run the WebSocket server."""
        async with serve(self._ws_handler, config.ws_host, config.ws_port):
            await asyncio.Future()  # run forever

    async def _ws_handler(self, websocket):
        """Handle a single WebSocket connection."""
        self._ws_clients.add(websocket)
        remote = websocket.remote_address
        log.info(f"WS client connected: {remote}")
        try:
            async for raw in websocket:
                try:
                    msg = json.loads(raw)
                    msg_type = msg.get("type", "")
                    msg_id = msg.get("id", "")

                    if msg_type == "command":
                        cmd = msg.get("command", "")
                        args = msg.get("args", {})

                        if cmd == "talk" and hasattr(self, '_handle_ws_talk'):
                            asyncio.run_coroutine_threadsafe(
                                self._ws_handle_talk(websocket, msg_id, args),
                                self._loop,
                            )
                        elif hasattr(self, '_handle_command'):
                            try:
                                result = self._handle_command(cmd, args, msg_id)
                                if result == "processing...":
                                    result = await self._ws_wait_result(msg_id, timeout=120)
                                await websocket.send(json.dumps({
                                    "type": "response", "id": msg_id, "result": result
                                }))
                            except Exception as e:
                                await websocket.send(json.dumps({
                                    "type": "error", "id": msg_id, "error": str(e)
                                }))
                        else:
                            await websocket.send(json.dumps({
                                "type": "error", "id": msg_id,
                                "error": f"Unknown command: {cmd}"
                            }))

                    elif msg_type == "ping":
                        await websocket.send(json.dumps({"type": "pong"}))

                except json.JSONDecodeError:
                    await websocket.send(json.dumps({
                        "type": "error", "error": "Invalid JSON"
                    }))
        except websockets.ConnectionClosed:
            pass
        finally:
            self._ws_clients.discard(websocket)
            log.info(f"WS client disconnected: {remote}")

    async def _ws_handle_talk(self, websocket, msg_id: str, args: dict):
        """Handle talk command — runs Being's conversational handler.

        Override _handle_ws_talk(message, readonly) in your Being for custom behavior.
        """
        message = args.get("message", "")
        readonly = args.get("readonly", False)
        if not message:
            await websocket.send(json.dumps({
                "type": "response", "id": msg_id, "result": "No message"
            }))
            return

        try:
            result = await self._handle_ws_talk(message, readonly)
            await websocket.send(json.dumps({
                "type": "response", "id": msg_id, "result": result
            }))
        except Exception as e:
            await websocket.send(json.dumps({
                "type": "error", "id": msg_id, "error": str(e)
            }))

    async def _ws_wait_result(self, cmd_id: str, timeout: int = 120) -> str:
        """Wait for an async command to complete by polling state."""
        start = time.time()
        while time.time() - start < timeout:
            if (hasattr(self, '_last_command_id') and
                    self._last_command_id == cmd_id and
                    self._last_result != "processing..."):
                return self._last_result
            await asyncio.sleep(0.5)
        return "Timeout waiting for response"

    def _ws_broadcast(self, event: str, data: dict):
        """Broadcast an event to all connected WebSocket clients."""
        if not hasattr(self, '_ws_clients') or not self._ws_clients:
            return
        msg = json.dumps({"type": "event", "event": event, "data": data})
        for ws in list(self._ws_clients):
            try:
                asyncio.run_coroutine_threadsafe(ws.send(msg), self._loop)
            except Exception:
                self._ws_clients.discard(ws)
