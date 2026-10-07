import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readdirSync, readFileSync, copyFileSync, chmodSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { mintGrant, revokeGrant, currentScope, allowedChats, pruneGrants, handlerKey, keyFile } from './scope.mjs';

const state = () => mkdtempSync(path.join(tmpdir(), 'scope-'));

test('no token, unknown token or revoked token is owner-only', () => {
  const s = state();
  assert.equal(currentScope({ state: s, token: '' }).scope, 'owner-only');
  assert.equal(currentScope({ state: s, token: 'made-up' }).scope, 'owner-only');
  const t = mintGrant('chats:a,b', { state: s });
  assert.equal(currentScope({ state: s, token: t }).scope, 'chats:a,b');
  revokeGrant(t, { state: s });
  assert.equal(currentScope({ state: s, token: t }).scope, 'owner-only');
});

test('only the hash is stored; expired and malformed grants fall back to owner-only', () => {
  const s = state();
  const t = mintGrant('full', { state: s });
  const [f] = readdirSync(path.join(s, 'grants'));
  assert.ok(!f.includes(t));
  writeFileSync(path.join(s, 'grants', f), JSON.stringify({ scope: 'full', expires: Date.now() - 1 }));
  assert.equal(currentScope({ state: s, token: t }).scope, 'owner-only');
  writeFileSync(path.join(s, 'grants', f), JSON.stringify({ scope: 'everything', expires: Date.now() + 1e6 }));
  assert.equal(currentScope({ state: s, token: t }).scope, 'owner-only');
  assert.equal(pruneGrants({ state: s }), 1);
});

test('bad scopes cannot be minted; chats parse', () => {
  assert.throws(() => mintGrant('chats:', { state: state() }));
  assert.throws(() => mintGrant('', { state: state() }));
  assert.deepEqual(allowedChats('chats:x,y'), ['x', 'y']);
  assert.deepEqual(allowedChats('full'), []);
});

// A kit copy with its own on-disk .env, as installed; the CLI reads state from there, not from process env.
const kit = (s) => {
  const d = mkdtempSync(path.join(tmpdir(), 'kit-'));
  for (const f of ['scope.mjs', 'kit-env.mjs']) copyFileSync(f, path.join(d, f));
  writeFileSync(path.join(d, '.env'), `BEING_STATE_DIR='${s}'\n`);
  return (args, env = {}, input) => spawnSync('node', [path.join(d, 'scope.mjs'), ...args],
    { env: { ...process.env, BEING_SEND_TOKEN: '', ...env }, encoding: 'utf8', input });
};

test('BEING_SEND_SCOPE and BEING_STATE_DIR in the environment are ignored', () => {
  const s = state(), run = kit(s);
  assert.equal(run(['show'], { BEING_SEND_SCOPE: 'full' }).stdout.trim(), 'owner-only');
  const evil = state(), t = mintGrant('full', { state: evil });   // a grant in a directory the run controls
  assert.equal(run(['show'], { BEING_STATE_DIR: evil, BEING_SEND_TOKEN: t }).stdout.trim(), 'owner-only');
});

test('owner-read-ok needs a real full or owner-only grant', () => {
  const s = state(), run = kit(s);
  const code = (tok) => run(['owner-read-ok'], { BEING_SEND_TOKEN: tok }).status;
  assert.equal(code(''), 3);
  assert.equal(code(mintGrant('chats:a', { state: s })), 3);
  assert.equal(code(mintGrant('owner-only', { state: s })), 0);
  assert.equal(code(mintGrant('full', { state: s })), 0);
});

test('a grant file written without the handler key is not honoured', () => {
  const s = state(), t = mintGrant('chats:a', { state: s });
  const [f] = readdirSync(path.join(s, 'grants'));
  const g = JSON.parse(readFileSync(path.join(s, 'grants', f), 'utf8'));
  writeFileSync(path.join(s, 'grants', f), JSON.stringify({ ...g, scope: 'full' }));   // escalate an existing grant
  assert.equal(currentScope({ state: s, token: t }).scope, 'owner-only');
  writeFileSync(path.join(s, 'grants', f), JSON.stringify({ scope: 'full', expires: Date.now() + 1e6 }));   // forged, unsigned
  assert.equal(currentScope({ state: s, token: t }).why, 'unsigned grant');
  assert.equal(pruneGrants({ state: s }), 1);
});

test('mint full needs the handler key: unreadable or loose key refuses', { skip: process.getuid?.() === 0 && 'root reads any file' }, () => {
  const s = state(), run = kit(s);
  const t = run(['mint', 'full', '1']);
  assert.equal(t.status, 0);
  assert.equal(run(['show'], { BEING_SEND_TOKEN: t.stdout.trim() }).stdout.trim(), 'full');
  chmodSync(keyFile(s), 0o000);   // what a separate model user sees in the two-user layout
  const r = run(['mint', 'full', '1']);
  assert.equal(r.status, 2); assert.equal(r.stdout, '');
  assert.equal(run(['show'], { BEING_SEND_TOKEN: t.stdout.trim() }).stdout.trim(), 'owner-only');
  chmodSync(keyFile(s), 0o644);
  assert.match(run(['mint', 'full', '1']).stderr, /must be mode 600/);
  assert.throws(() => handlerKey({ state: state() }), /no handler key/);
});
