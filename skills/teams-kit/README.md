# Teams Kit — a Being on Microsoft Teams and Outlook

Gives a Being its own Microsoft 365 identity and a message pipeline that runs unattended on the Being's host:

```
being-teams (loop, every 30 s, no model)
 ├─ teams-presence.mjs      green while running, Offline within 15 min after it stops
 ├─ teams-detect.mjs        new messages addressed to the Being → state/queue.jsonl
 │    └─ being-handle triage   fast model, read-only, one call per chat: none / react / short reply + needsWork → teams-ack.mjs
 │         └─ being-handle work   Claude Code daily session per lane (owner, each teammate chat), own send grant per run
 │              ├─ being-job agent|codex|run   long work, detached; wakes the session to verify and report
 │              └─ voice pass   fast model rewords queued replies; numbers and links must survive
 ├─ mail.mjs --detect       log + desktop notification, never auto-reply
 └─ being-watchdog          one alert when a job or run goes idle; marks vanished jobs as died
```

One fast-model session and one work session per day **per lane**: the owner's pair (named by date, opened by
`bin/<name> claude today` / `codex today`) and one pair per teammate chat, so the Being keeps each conversation's context
for the day without one person's run ever resuming another's. Teammate runs are fenced (`GUARDRAILS.md`, Lanes).

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
| `team-fence.py` | PreToolUse hook for teammate runs: refuses private paths, other sessions, credentials, owner tools |
| `teams-fetch-attachment.mjs` | open an inline image or shared file from a message (exit 3 = not shared with the Being) |
| `owner-read`, `owner-mail` | read-only views of the owner's chats and mail (owner sign-in: opt-in, two-user hosts only) |
| `GUARDRAILS.md` | what is automatic, what is enforced, what is never allowed |

## Set up (about 15 minutes once the account exists)

**Host: Linux.** The runner and handler use `flock`, `setsid`, GNU `find`/`readlink` and systemd user units; on macOS they
fail partly and quietly. `install.sh --with teams-kit` checks for them. Needs Node.js 20+ and Python 3.10+.

1. **Accounts.** A licensed M365 user for the Being, and an Entra app registration: public client, "Allow public client
   flows" on, delegated permissions `Chat.ReadWrite ChatMessage.Send Chat.Create User.Read Presence.ReadWrite Mail.ReadWrite
   Mail.Send Files.ReadWrite`, plus `Files.Read.All` to open files people attach. Some tenants require admin consent; ask
   your tenant admin.
2. **Install.** `npm install`, then copy `.env.example` to `.env` (`chmod 600`) and fill it. `install.sh --with teams-kit`
   does the copy and prefills the paths and names.
3. **Sign in as the Being** (device code; refuses any other account):
   `set -a; . ./.env; set +a; node teams-login-device.mjs --upn "$BEING_UPN" --cache "$BEING_CACHE"`
4. **Owner ids.** `OWNER_UPN` and `OWNER_OID` (the owner's object id; visible in the Entra portal).
5. **Owner delegate sign-in: off by default; two-user hosts only.** On a host where the model runs as the same OS user,
   a prompt-injected run can read this token and post as the owner; no check can stop that (`GUARDRAILS.md`, Threat model).
   Only on a two-user host: set `BEING_OWNER_DELEGATE=1` in `.env`, then sign in to a separate cache with narrowed scopes:
   `node teams-login-device.mjs --upn "$OWNER_UPN" --cache "$OWNER_CACHE" --scopes Chat.ReadWrite,ChatMessage.Send,Mail.ReadWrite,Mail.Send,User.Read`
   Without it, drafts still reach the owner with the text to send by hand.
6. **Check:** `node teams-send-dm.mjs --whoami`, then `echo hello | node teams-send-dm.mjs` (lands in the owner's 1:1),
   `npm test`, and `./being-teams doctor`. Doctor fails on a same-user host: there the kit stops mistakes, not injection.
   If no second user is possible, set `BEING_SINGLE_USER_ACK=1` (owner sign-in off) to accept that knowingly (GUARDRAILS.md).
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
- Poll by default: subscriptions expire and miss messages while the host sleeps; a 30 s poll costs ~1 s. Webhooks in
  front of the same queue are fine if they follow the rules in docs/ARCHITECTURE.md (Watching), with the poll as catch-up.
- Never answer about an attachment you have not opened (`teams-fetch-attachment.mjs`); if it is not shared, say so.
- Never 👍 a question: it can read as "yes" or as a brush-off.
- A handler run ends when it replies and kills anything it left in the background: long work goes to `being-job`.
- After two failures outside the Being's control, `being-blocker`, not a retry loop.
- Teams is a retained corporate record: nothing personal about anyone goes into it.

## Detection limits
Each tick reads up to `BEING_DETECT_CHATS` chats (default 50, most recently active first where Graph allows ordering) and
the newest `BEING_DETECT_MESSAGES` messages in each (default 8, max 50). A chat that falls outside the first N, or gets more
than M messages between two ticks, reads further back up to `BEING_DETECT_PAGES` pages (default 5) and logs a warning if
even that is all new. Raising the limits costs more Graph calls per tick, so size them to the Being's traffic.
In groups the Being wakes on an @mention or its name as a word; `BEING_NAME_ALIASES` adds names, and `BEING_NAME_STOPLIST`
lists phrases that contain the name but are not about the Being (a place, a product). Triage answers "named in passing"
with action none, but each such wake still costs a fast-model call, so keep the stop-list current.

## Script reference

```
teams-detect.mjs <ISO8601-watermark>
    exit 0 nothing new | 10 new (JSON on stdout) | 11 new, but a chat failed transiently (queue them, keep the watermark)
    exit 1 error (do NOT advance the watermark). Env: BEING_UPN, BEING_NAME, BEING_CACHE (owner values for the delegate
    lane), OWNER_OID (optional), BEING_DETECT_CHATS / _MESSAGES / _PAGES, BEING_NAME_ALIASES / _STOPLIST
    (see "Detection limits").
teams-fetch-attachment.mjs <attachments[].url from the message> [--out <dir>]
    Inline images (Graph hostedContents) and OneDrive/SharePoint file cards; prints {"file","bytes","type"}.
    exit 3 NOT_SHARED (ask the sender to share it with the Being) | 2 not a Microsoft attachment URL, refused | 1 error.
teams-read.mjs --whoami | --list [--top N] | --find <text> | <upn> [--top N]
teams-read.mjs --chat <chatId> [--top N] | --since <messageId> (exit 2 if not found) | --members
    --as <upn>   read as another identity present in BEING_CACHE (used by owner-read)
teams-send-dm.mjs [<upn>] < msg            1:1 with that person (default OWNER_UPN), created if missing
    Every sender here posts only as the Being: the owner's UPN, cache or object id (kit .env on disk) exits 3.
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
    The owner's UPN or cache is refused unless BEING_OWNER_DELEGATE=1 in .env (then a warning is printed).
mail.mjs --list [--top N] [--unread] | --search <text> [--top N] | --read <id> | --attachments <id> [--save <dir>]
mail.mjs --detect <ISO8601-watermark>      exit 0 none, 10 new (JSON on stdout), 1 error
mail.mjs --send --to a[,b] --subject S [--cc c] [--attach f1,f2] < body.html   (each file < 3 MB)
draft-for-owner.mjs --chat <owner chatId> [--re "<their message>"] < draft.md     target label resolved from Graph
    Refused: a draft for the owner's 1:1 with the Being, or text that is itself a "send Dn" command.
draft-for-owner.mjs --mail --to a[,b] [--cc c] --subject S [--reply-to <owner messageId>] [--attach /abs/f] < draft.md
approve.mjs send|edit|skip|save <Dn> --chat <owner 1:1 chatId> --msg <owner's command messageId>
    Called by being-handle for commands the owner typed; re-reads the command and prompt from Graph (GUARDRAILS.md).
scope.mjs mint <full|owner-only|chats:id,...> [ttlHours] | revoke < token | show | owner-read-ok | prune
    mint is the handler's: it needs state/handler.key (0600). Grants without its HMAC are owner-only. In the two-user
    layout only the kit user can read the key; on a same-user host any run can, so mint cannot be restricted (doctor fails).
being-job agent <name> [--small] --notify <chatId> "<self-contained task>"   headless Claude Code
being-job codex <name> [--network] --notify <chatId> "<task>"               Codex, workspace-write sandbox, no network unless --network
    BEING_JOB_ADD_DIRS=/a:/b   extra dirs Codex may write (e.g. a repo worktree)
being-job run <name> --notify <chatId> -- <command...>                     a plain command
being-job list | status <id> | log <id> [n]     from a teammate chat's run: only that chat's own jobs (others exit 3)
being-status [--actions N] [--chat <chatId>]   live view; --chat: that chat's queue and jobs only (fed to its triage)
being-blocker "<task>" "<what failed, with the exact error>" "<what you need from the owner>"
being-teams doctor     file modes; FAIL (exit 1) on a same-user host, louder if an owner token is readable, or if the
                       model user can reach .env, caches, grants or the handler key. WARN instead with
                       BEING_SINGLE_USER_ACK=1 and no owner sign-in
being-handle warm | triage | work | voice
    triage: queue.jsonl → owner decisions to approve.mjs → one fast-model call per chat, in its lane's session → acks → work.jsonl
            (fast client: no file tools, empty working directory; everything it needs is in the prompt)
    work:   work.jsonl → one call per lane in that lane's session (owner, delegate, each teammate chat; job results go back
            to the lane that started the job), each with a fresh grant revoked at the end; teammate runs are fenced
    voice:  queued messages → fast model rewords, per lane → sent (after every work run)
```
