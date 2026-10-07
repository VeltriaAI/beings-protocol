import test from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import path from 'node:path';
import { spawnSync } from 'node:child_process';
import { mintGrant, revokeGrant, currentScope, allowedChats, pruneGrants } from './scope.mjs';

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

test('BEING_SEND_SCOPE in the environment is ignored', () => {
  const s = state();
  const r = spawnSync('node', ['scope.mjs', 'show'], { env: { ...process.env, BEING_STATE_DIR: s, BEING_SEND_SCOPE: 'full', BEING_SEND_TOKEN: '' }, encoding: 'utf8' });
  assert.equal(r.stdout.trim(), 'owner-only');
});

test('owner-read-ok needs a real full or owner-only grant', () => {
  const s = state();
  const run = (tok) => spawnSync('node', ['scope.mjs', 'owner-read-ok'], { env: { ...process.env, BEING_STATE_DIR: s, BEING_SEND_TOKEN: tok } }).status;
  assert.equal(run(''), 3);
  assert.equal(run(mintGrant('chats:a', { state: s })), 3);
  assert.equal(run(mintGrant('owner-only', { state: s })), 0);
  assert.equal(run(mintGrant('full', { state: s })), 0);
});
