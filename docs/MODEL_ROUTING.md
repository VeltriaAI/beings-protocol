# Model Routing — Right Model, Right Step

Route by the weight of the step, not by habit. Cheap, fast steps run often; strong models run where judgment pays.

| Step | Frequency | Model | Effort | Setting |
|---|---|---|---|---|
| Triage (ack decision, status answers) | every message | fast (e.g. a Haiku-class model, or Codex at low effort) | low | `BEING_FAST_CLIENT`, `BEING_FAST_MODEL`, `BEING_FAST_EFFORT` |
| Voice (reword outgoing messages) | every reply | same fast model | low | same |
| Work session (do the task, decide) | per message needing work | strong (Opus-class) | default | `BEING_SESSION_MODEL` |
| Big jobs (research, reviews, multi-step builds, audits) | a few per day | strong | default | `BEING_JOB_MODEL` |
| Small jobs (lookups, account chores, probes, file moves) | many | mid (Sonnet-class) | default | `being-job agent <n> --small`, `BEING_JOB_MODEL_SMALL` |
| Self-contained coding/build jobs | as needed | Codex | medium | `being-job codex` |

Guidelines:

- **Pin models explicitly** in every launcher (`--model`), so a client default change or a per-model usage limit does not
  silently move work to a model you did not choose. When one model hits a limit, switch the env var, not the code.
- **Fast models never act.** Triage and voice run read-only and return JSON; scripts apply their decisions.
- **Guard the fast model's output.** The voice pass may not drop a number or link; if it does, the original text is sent.
- **One session per day per client** keeps context warm without reloading the whole history for each message.
- Use model aliases (`opus`, `sonnet`, `haiku`) or full ids as your client accepts; check with a one-line run before relying
  on a new id.
