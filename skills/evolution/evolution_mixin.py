"""EvolutionMixin — self-learning with extensible pattern detection.

Provides a structured reflection loop that:
1. Collects performance data (override _collect_evolution_data)
2. Detects patterns (override _detect_patterns)
3. Optionally triggers self-modification via evolve()

This is a Being-agnostic extraction from the Evolution Protocol.
Domain-specific pattern detection should be added by subclassing
and overriding _detect_patterns().
"""

import logging
import time
from pathlib import Path

from .config import EvolutionConfig

log = logging.getLogger("beings.evolution")


class EvolutionMixin:
    """Mixin that adds self-learning and optional auto-evolution to any Being.

    Requirements on the host class:
    - self.config.evolution: EvolutionConfig instance
    - self._agent_busy: bool indicating if the Being's agent is currently running
    - self._invoke_being(prompt, timeout): method to run the Being's LLM agent

    Optional (for richer data collection):
    - self._collect_evolution_data(): override to return domain-specific metrics
    - self._detect_patterns(data): override to add domain-specific pattern detection
    """

    def _evolution_reflect(self):
        """Enhanced reflection — collects structured data, detects patterns.

        Call this from your Being's main loop at regular intervals.
        """
        if getattr(self, '_agent_busy', False):
            return

        try:
            config = self._get_evolution_config()
            data = self._collect_evolution_data()

            # Ask Being to reflect on structured data
            prompt = self._build_reflection_prompt(data)
            if hasattr(self, '_invoke_being'):
                self._invoke_being(prompt, timeout=60)

            # Detect patterns from accumulated data
            patterns = self._detect_patterns(data)
            if patterns:
                self._on_patterns_detected(patterns)

                # Check if we should trigger self-evolution
                if config.auto_evolve:
                    should, goal = self._should_trigger_evolution(patterns, config)
                    if should:
                        log.info(f"Auto-evolution triggered: {goal}")
                        from .evolve import evolve
                        repo_root = self._get_repo_root()
                        result = evolve(
                            goal,
                            repo_root=repo_root,
                            scope="agent/",
                            max_budget_usd=config.max_budget_per_evolve_usd,
                            config=config,
                            being_name=getattr(self, 'name', 'Being'),
                        )
                        log.info(f"Auto-evolution result: {result[:200]}")

            log.info("Evolution reflection complete")
        except Exception as e:
            log.warning(f"Evolution reflection error: {e}")

    def _get_evolution_config(self) -> EvolutionConfig:
        """Get the evolution config. Override if your config is stored differently."""
        if hasattr(self, 'config') and hasattr(self.config, 'evolution'):
            return self.config.evolution
        return EvolutionConfig()

    def _get_repo_root(self) -> Path:
        """Get the repository root. Override per Being."""
        return Path(__file__).parent.parent.parent

    def _collect_evolution_data(self) -> dict:
        """Gather structured performance data.

        Override this in your Being to collect domain-specific metrics.
        Returns a dict with whatever keys your _detect_patterns expects.

        Default returns an empty data structure.
        """
        return {
            "metrics": {},
            "feedback_summary": {"positive": 0, "negative": 0},
            "recent_events": [],
        }

    def _build_reflection_prompt(self, data: dict) -> str:
        """Build the reflection prompt from collected data.

        Override for domain-specific reflection prompts.
        """
        return (
            f"SELF-REFLECTION TIME. Here's your performance data:\n\n"
            f"{data}\n\n"
            f"What patterns do you see? What worked and what didn't?\n"
            f"Be specific about what to improve."
        )

    def _detect_patterns(self, data: dict) -> list[dict]:
        """Find recurring patterns in performance data.

        Override this in your Being to add domain-specific pattern detection.
        Each pattern should be a dict with:
        - type: str — pattern identifier
        - description: str — human-readable description
        - confidence: float — 0.0 to 1.0
        - occurrences: int — how many times observed
        - suggested_action: str — what to do about it

        Default implementation detects feedback imbalance only.
        """
        patterns = []

        # Pattern: negative feedback outnumbers positive
        fb = data.get("feedback_summary", {})
        negative = fb.get("negative", 0)
        positive = fb.get("positive", 0)
        if negative > positive and negative >= 3:
            patterns.append({
                "type": "negative_feedback",
                "description": (
                    f"More negative feedback ({negative}) than positive ({positive}). "
                    f"Performance needs improvement."
                ),
                "confidence": 0.7,
                "occurrences": negative,
                "suggested_action": "Analyze negative feedback patterns and adjust behavior",
            })

        return patterns

    def _on_patterns_detected(self, patterns: list[dict]):
        """Called when patterns are detected. Override to store/act on them.

        Default just logs them.
        """
        for p in patterns:
            log.info(
                f"Pattern detected: {p['type']} "
                f"(confidence={p['confidence']:.2f}, occurrences={p['occurrences']})"
            )

    def _should_trigger_evolution(
        self, patterns: list[dict], config: EvolutionConfig
    ) -> tuple[bool, str]:
        """Decide if patterns warrant auto-evolution.

        Override for custom triggering logic. Default requires
        confidence >= 0.8 and occurrences >= 5.
        """
        if not config.auto_evolve:
            return False, ""

        # Find strongest pattern
        for p in sorted(patterns, key=lambda x: x["confidence"], reverse=True):
            if p["confidence"] >= 0.8 and p["occurrences"] >= 5:
                return True, p["suggested_action"]

        return False, ""
