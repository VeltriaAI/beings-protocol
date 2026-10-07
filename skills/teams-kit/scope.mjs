#!/usr/bin/env node
// Send grants: the handler mints an opaque per-run token; only its hash and scope are stored under state/grants.
// No token or an unknown/expired one means owner-only, so dropping the token can only narrow a run. See GUARDRAILS.md.
import { readFileSync, writeFileSync, mkdirSync, rmSync, existsSync, readdirSync } from 'node:fs';
import { createHash, randomBytes } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';

const SCOPE_RE = /^(full|owner-only|chats:[^,\s]+(,[^,\s]+)*)$/;
const dir = (state) => {
  const s = state || process.env.BEING_STATE_DIR;
  if (!s) throw new Error('missing env BEING_STATE_DIR; see .env.example');
  return path.join(s, 'grants');
};
const hash = (t) => createHash('sha256').update(t).digest('hex');

export function mintGrant(scope, { state, ttlHours = 12 } = {}) {
  if (!SCOPE_RE.test(scope)) throw new Error(`bad scope "${scope}"`);
  const d = dir(state); mkdirSync(d, { recursive: true, mode: 0o700 });
  const token = randomBytes(24).toString('base64url');
  writeFileSync(path.join(d, `${hash(token)}.json`), JSON.stringify({ scope, expires: Date.now() + ttlHours * 3600e3 }), { mode: 0o600 });
  return token;
}

export function revokeGrant(token, { state } = {}) {
  if (token) rmSync(path.join(dir(state), `${hash(token)}.json`), { force: true });
}

// Effective scope of this process: "full", "owner-only" or "chats:<id>,...". Never read from a plain env var.
export function currentScope({ state, token = process.env.BEING_SEND_TOKEN } = {}) {
  if (!token) return { scope: 'owner-only', why: 'no grant' };
  let f;
  try { f = path.join(dir(state), `${hash(token)}.json`); } catch { return { scope: 'owner-only', why: 'no state dir' }; }
  if (!existsSync(f)) return { scope: 'owner-only', why: 'unknown grant' };
  try {
    const g = JSON.parse(readFileSync(f, 'utf8'));
    if (!SCOPE_RE.test(g.scope || '')) return { scope: 'owner-only', why: 'bad grant' };
    if (!(g.expires > Date.now())) return { scope: 'owner-only', why: 'expired grant' };
    return { scope: g.scope, why: 'grant' };
  } catch { return { scope: 'owner-only', why: 'unreadable grant' }; }
}

export const allowedChats = (scope) => (scope.startsWith('chats:') ? scope.slice(6).split(',').filter(Boolean) : []);

export function pruneGrants({ state } = {}) {
  const d = dir(state); if (!existsSync(d)) return 0;
  let n = 0;
  for (const f of readdirSync(d)) {
    try {
      const g = JSON.parse(readFileSync(path.join(d, f), 'utf8'));
      if (!(g.expires > Date.now()) || !SCOPE_RE.test(g.scope || '')) { rmSync(path.join(d, f)); n++; }
    }
    catch { rmSync(path.join(d, f), { force: true }); n++; }
  }
  return n;
}

// CLI for the handler and operators: mint <scope> [ttlHours] | revoke (token on stdin) | show | owner-read-ok | prune
if (process.argv[1] && path.resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  const [cmd, a, b] = process.argv.slice(2);
  try {
    if (cmd === 'mint') console.log(mintGrant(a, { ttlHours: b ? Number(b) : 12 }));
    else if (cmd === 'revoke') revokeGrant(readFileSync(0, 'utf8').trim());
    else if (cmd === 'show') console.log(currentScope().scope);
    else if (cmd === 'owner-read-ok') { const c = currentScope(); process.exit(c.why === 'grant' && ['full', 'owner-only'].includes(c.scope) ? 0 : 3); }
    else if (cmd === 'prune') console.log(`pruned ${pruneGrants()}`);
    else { console.error('usage: scope.mjs mint <full|owner-only|chats:id,...> [ttlHours] | revoke < token | show | owner-read-ok | prune'); process.exit(2); }
  } catch (e) { console.error(e.message); process.exit(2); }
}
