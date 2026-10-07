# Teams Kit — a Being on Microsoft Teams and Outlook

Gives a Being its own Microsoft 365 identity and a message pipeline that runs unattended on the Being's host:

```
being-teams (loop, every 30 s, no model)
 ├─ teams-presence.mjs      green while running, Offline within 15 min after it stops
 ├─ teams-detect.mjs        new messages addressed to the Being → state/queue.jsonl
 │    └─ being-handle triage   fast model, read-only, one call per chat: none / react / short reply + needsWork → teams-ack.mjs
 │         └─ being-handle work   Claude Code daily session, one call per lane, each with its own send grant
 │              ├─ being-job agent|codex|run   long work, detached; wakes the session to verify and report
 │              └─ voice pass   fast model rewords queued replies; numbers and links must survive
 ├─ mail.mjs --detect       log + desktop notification, never auto-reply
 └─ being-watchdog          one alert when a job or run goes idle; marks vanished jobs as died
```

One fast-model session and one work session per day per client (named by date), so the Being keeps the day's context
without reloading it for every message. `bin/<name> claude today` / `codex today` opens them.

## Files
| File | Role |
|---|---|
| `being-teams` | runner: `up / down / status / logs / handler / inbox / autostart on` |
| `being-handle` | `triage / work / voice / warm` stages; all prompt text lives here |
| `being-job` | `agent / codex / run` background jobs; `list / status / log` |
| `being-blocker` | tell the owner at once that something is blocked |
| `being-watchdog`, `being-status` | stall alerts; live "what is running" view (also fed to triage) |
| `teams-*.mjs`, `mail.mjs` | Graph calls: detect, read, send, ack, presence, mailbox |
| `draft-for-owner.mjs`, `approve.mjs`, `approval.mjs` | write as the owner only via a draft the owner approves in Teams |
| `scope.mjs`, `secrets.mjs` | per-run send grants; outgoing-text secret filter |
| `owner-read`, `owner-mail` | read-only views of the owner's chats and mail (optional delegate sign-in) |
| `GUARDRAILS.md` | what is automatic, what is enforced, what is never allowed |

## Set up (about 15 minutes once the account exists)

1. **Accounts.** A licensed M365 user for the Being, and an Entra app registration: public client, "Allow public client
   flows" on, delegated permissions `Chat.ReadWrite ChatMessage.Send Chat.Create User.Read Presence.ReadWrite Mail.ReadWrite
   Mail.Send Files.ReadWrite`. Some tenants require admin consent; ask your tenant admin.
2. **Install.** `npm install`, then copy `.env.example` to `.env` (`chmod 600`) and fill it. `install.sh --with teams-kit`
   does the copy and prefills the paths and names.
3. **Sign in as the Being** (device code; refuses any other account):
   `set -a; . ./.env; set +a; node teams-login-device.mjs --upn "$BEING_UPN" --cache "$BEING_CACHE"`
4. **Owner ids.** `OWNER_UPN` and `OWNER_OID` (the owner's object id; visible in the Entra portal).
5. **Optional delegate sign-in for the owner**, in a separate cache, narrowed scopes. Read the threat model in
   `GUARDRAILS.md` first: on a host where the model runs as the same OS user, a prompt-injected run could use this token.
   `node teams-login-device.mjs --upn "$OWNER_UPN" --cache "$OWNER_CACHE" --scopes Chat.ReadWrite,ChatMessage.Send,Mail.ReadWrite,Mail.Send,User.Read`
6. **Check:** `node teams-send-dm.mjs --whoami`, then `echo hello | node teams-send-dm.mjs` (lands in the owner's 1:1),
   `npm test`, and `./being-teams doctor` (file modes and which isolation column of the threat model applies).
7. **Run:** `./being-teams up` (or `autostart on` for a systemd user unit). `./being-teams inbox` shows traffic.

## Talking to it
- People message the Being in Teams. In groups it answers only when @mentioned or named.
- The owner approves drafts by typing `send D3`, `edit D3 <text>`, `skip D3`, `save D3` (email: leave in Outlook Drafts)
  in their 1:1 with the Being. The prompt names the real target chat and a fingerprint; approval is re-checked in Graph.
- "Status?" is answered by triage from `being-status` in seconds, even while a long run is busy.

## Model routing
`BEING_FAST_*` drive triage and voice (low effort, seconds); `BEING_SESSION_MODEL` drives the work session;
`BEING_JOB_MODEL` / `BEING_JOB_MODEL_SMALL` drive background jobs (`being-job agent <name> --small ...`).
See `docs/MODEL_ROUTING.md`.

## Design rules
- One identity per cache file, so a message can never go out under the wrong name; senders are pinned and `/me`-checked.
- MSAL caches must be written back after every silent refresh, or the next run authenticates against a dead token.
- Poll, don't subscribe: Graph subscriptions expire hourly and lose messages while the host sleeps; a 30 s poll costs ~1 s.
- Never 👍 a question: it can read as "yes" or as a brush-off.
- A handler run ends when it replies and kills anything it left in the background: long work goes to `being-job`.
- After two failures outside the Being's control, `being-blocker`, not a retry loop.
- Teams is a retained corporate record: nothing personal about anyone goes into it.

## Detection limits
Each tick reads up to `BEING_DETECT_CHATS` chats (default 50, most recently active first where Graph allows ordering) and
the newest `BEING_DETECT_MESSAGES` messages in each (default 8, max 50). A chat that falls outside the first N, or gets more
than M messages between two ticks, can be missed; the watcher logs a warning when a chat's whole page is new. Raising either
costs one more Graph call per chat per tick (~30 s), so size them to the Being's traffic.

## Script reference

```
teams-detect.mjs <ISO8601-watermark>
    exit 0 nothing new | 10 new (JSON on stdout) | 11 new, but a chat failed transiently (queue them, keep the watermark)
    exit 1 error (do NOT advance the watermark). Env: BEING_UPN, BEING_NAME, BEING_CACHE (owner values for the delegate
    lane), OWNER_OID (optional), BEING_DETECT_CHATS / BEING_DETECT_MESSAGES (see "Detection limits"). Polling every
    ~30 s is used because Graph subscriptions expire and miss messages while the host sleeps.
teams-read.mjs --whoami | --list [--top N] | --find <text> | <upn> [--top N]
teams-read.mjs --chat <chatId> [--top N] | --since <messageId> (exit 2 if not found) | --members
    --as <upn>   read as another identity present in BEING_CACHE (used by owner-read)
teams-send-dm.mjs [<upn>] < msg            1:1 with that person (default OWNER_UPN), created if missing
teams-send-dm.mjs --chat <chatId> < msg
    --reply-to <messageId>  quote it (with --chat defaults to BEING_REPLY_TO) | --no-quote
    --attach-url <url> [--attach-name <n>]  file card for a OneDrive/SharePoint item
    --verbatim  skip the voice pass | --whoami  verify the sender token
    Scope comes from the grant named by BEING_SEND_TOKEN (scope.mjs): full | owner-only | chats:<id>,<id>.
    No valid grant = owner-only. Blocked target, a prompt fingerprint or secret-looking text: exit 3, nothing sent.
    With BEING_VOICE=fast the message is queued in $BEING_STATE_DIR/outbox and sent after the voice pass.
teams-ack.mjs < {"messages":[detect hits],"actions":[{chatId,messageId,action,text,emoji}]}
    action none | react | reply. With no decision (triage failed) a 1:1 message gets a 👍. exit 1 if any failed.
teams-presence.mjs available | offline | status
    available lasts 15 min; the runner refreshes it every ~5 min, so Teams drops to Offline when it stops.
teams-login-device.mjs --upn <user@your-tenant> --cache <file> [--scopes a,b,c]
mail.mjs --list [--top N] [--unread] | --search <text> [--top N] | --read <id> | --attachments <id> [--save <dir>]
mail.mjs --detect <ISO8601-watermark>      exit 0 none, 10 new (JSON on stdout), 1 error
mail.mjs --send --to a[,b] --subject S [--cc c] [--attach f1,f2] < body.html   (each file < 3 MB)
draft-for-owner.mjs --chat <owner chatId> [--re "<their message>"] < draft.md     target label resolved from Graph
draft-for-owner.mjs --mail --to a[,b] [--cc c] --subject S [--reply-to <owner messageId>] [--attach /abs/f] < draft.md
approve.mjs send|edit|skip|save <Dn> --chat <owner 1:1 chatId> --msg <owner's command messageId>
    Called by being-handle for commands the owner typed; re-reads the command and prompt from Graph (GUARDRAILS.md).
scope.mjs mint <full|owner-only|chats:id,...> [ttlHours] | revoke < token | show | owner-read-ok | prune
    Operators testing by hand: BEING_SEND_TOKEN=$(node scope.mjs mint full 1) node teams-send-dm.mjs --chat <id> < msg
being-job agent <name> [--small] --notify <chatId> "<self-contained task>"   headless Claude Code
being-job codex <name> --notify <chatId> "<self-contained task>"             Codex, workspace-write sandbox
    BEING_JOB_ADD_DIRS=/a:/b   extra dirs Codex may write (e.g. a repo worktree)
being-job run <name> --notify <chatId> -- <command...>                     a plain command
being-job list | status <id> | log <id> [n]
being-blocker "<task>" "<what failed, with the exact error>" "<what you need from the owner>"
being-teams doctor     .env and cache modes, and whether the model user can reach them (exit 1 if not isolated)
being-handle warm | triage | work | voice
    triage: queue.jsonl → owner decisions to approve.mjs → one fast-model call per chat → acks → work.jsonl
    work:   work.jsonl → work session, one call per lane, each with a fresh grant revoked when the run ends
    voice:  queued messages → fast model rewords → sent (after every work run)
```
