#!/usr/bin/env node
// Send grants: the handler mints an opaque per-run token; only its hash, scope and a MAC are stored under state/grants.
// No token or an unknown/expired/unsigned one means owner-only, so dropping the token can only narrow a run. See GUARDRAILS.md.
import { readFileSync, writeFileSync, mkdirSync, rmSync, existsSync, readdirSync, statSync } from 'node:fs';
import { createHash, createHmac, randomBytes, timingSafeEqual } from 'node:crypto';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { kitEnv } from './kit-env.mjs';

const SCOPE_RE = /^(full|owner-only|chats:[^,\s]+(,[^,\s]+)*)$/;
// State comes from the on-disk .env, so a run cannot point grants at a directory it controls.
const stateOf = (state) => {
  const s = state || kitEnv().BEING_STATE_DIR;
  if (!s) throw new Error('BEING_STATE_DIR missing from the kit .env');
  return s;
};
const dir = (state) => path.join(stateOf(state), 'grants');
const hash = (t) => createHash('sha256').update(t).digest('hex');
export const keyFile = (state) => path.join(stateOf(state), 'handler.key');

// Minting authority = reading state/handler.key (0600, kit user only). Created on first mint by the handler.
export function handlerKey({ state, create = false } = {}) {
  const f = keyFile(state);
  if (!existsSync(f)) {
    if (!create) throw new Error('no handler key');
    mkdirSync(path.dirname(f), { recursive: true, mode: 0o700 });
    try { writeFileSync(f, randomBytes(32).toString('hex'), { mode: 0o600, flag: 'wx' }); } catch (e) { if (e.code !== 'EEXIST') throw e; }
  }
  if (statSync(f).mode & 0o077) throw new Error(`handler key ${f} must be mode 600`);
  return readFileSync(f, 'utf8').trim();
}
const mac = (key, th, scope, expires) => createHmac('sha256', key).update(`${th}|${scope}|${expires}`).digest('hex');

export function mintGrant(scope, { state, ttlHours = 12 } = {}) {
  if (!SCOPE_RE.test(scope)) throw new Error(`bad scope "${scope}"`);
  const key = handlerKey({ state, create: true });
  const d = dir(state); mkdirSync(d, { recursive: true, mode: 0o700 });
  const token = randomBytes(24).toString('base64url'), th = hash(token), expires = Date.now() + ttlHours * 3600e3;
  writeFileSync(path.join(d, `${th}.json`), JSON.stringify({ scope, expires, mac: mac(key, th, scope, expires) }), { mode: 0o600 });
  return token;
}

export function revokeGrant(token, { state } = {}) {
  if (token) rmSync(path.join(dir(state), `${hash(token)}.json`), { force: true });
}

// Effective scope of this process: "full", "owner-only" or "chats:<id>,...". Never read from a plain env var.
export function currentScope({ state, token = process.env.BEING_SEND_TOKEN } = {}) {
  if (!token) return { scope: 'owner-only', why: 'no grant' };
  let f, key;
  try { f = path.join(dir(state), `${hash(token)}.json`); } catch { return { scope: 'owner-only', why: 'no state dir' }; }
  if (!existsSync(f)) return { scope: 'owner-only', why: 'unknown grant' };
  try { key = handlerKey({ state }); } catch { return { scope: 'owner-only', why: 'no handler key' }; }
  try {
    const g = JSON.parse(readFileSync(f, 'utf8'));
    if (!SCOPE_RE.test(g.scope || '')) return { scope: 'owner-only', why: 'bad grant' };
    if (!(g.expires > Date.now())) return { scope: 'owner-only', why: 'expired grant' };
    const want = Buffer.from(mac(key, hash(token), g.scope, g.expires)), got = Buffer.from(String(g.mac || ''));
    if (got.length !== want.length || !timingSafeEqual(got, want)) return { scope: 'owner-only', why: 'unsigned grant' };
    return { scope: g.scope, why: 'grant' };
  } catch { return { scope: 'owner-only', why: 'unreadable grant' }; }
}

export const allowedChats = (scope) => (scope.startsWith('chats:') ? scope.slice(6).split(',').filter(Boolean) : []);

export function pruneGrants({ state } = {}) {
  const d = dir(state); if (!existsSync(d)) return 0;
  let n = 0, key = null;
  try { key = handlerKey({ state }); } catch {}
  for (const f of readdirSync(d)) {
    try {
      const g = JSON.parse(readFileSync(path.join(d, f), 'utf8'));
      const signed = key && g.mac === mac(key, f.replace(/\.json$/, ''), g.scope, g.expires);
      if (!(g.expires > Date.now()) || !SCOPE_RE.test(g.scope || '') || !signed) { rmSync(path.join(d, f)); n++; }
    }
    catch { rmSync(path.join(d, f), { force: true }); n++; }
  }
  return n;
}

// CLI for the handler: mint <scope> [ttlHours] (needs the handler key) | revoke (token on stdin) | show | owner-read-ok | prune
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
