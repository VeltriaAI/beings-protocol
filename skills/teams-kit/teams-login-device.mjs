#!/usr/bin/env node
// Device-code sign-in for one identity into its own 0600 MSAL cache; refuses any other account.
// Usage: README.md "Script reference".
import { writeFileSync } from 'node:fs';
import { msal, fail } from './graph.mjs';

const a = process.argv.slice(2);
const opt = (n) => { const i = a.indexOf(n); return i === -1 ? null : a[i + 1]; };
const UPN = (opt('--upn') || '').toLowerCase(), CACHE = opt('--cache');
if (!UPN || !CACHE) fail('usage: teams-login-device.mjs --upn <user@your-tenant> --cache <file> [--scopes a,b,c]', 2);
const DEFAULT_SCOPES = ['Chat.ReadWrite', 'ChatMessage.Send', 'Chat.Create', 'User.Read', 'Files.ReadWrite',
  'Presence.ReadWrite', 'Mail.ReadWrite', 'Mail.Send'];
// --scopes narrows the grant, e.g. a read-mostly delegate sign-in for the owner.
const SCOPES = opt('--scopes') ? opt('--scopes').split(',').map((x) => x.trim()).filter(Boolean) : DEFAULT_SCOPES;

const r = await msal(CACHE).acquireTokenByDeviceCode({ scopes: SCOPES, deviceCodeCallback: (m) => console.log(m.message) });
const got = (r.account?.username || '').toLowerCase();
if (got !== UPN) {
  try { writeFileSync(CACHE, '{}', { mode: 0o600 }); } catch {}
  fail(`REFUSED: signed in as ${got}, expected ${UPN}. Cache wiped.`, 2);
}
console.log(`ok: ${got} (object id ${r.account?.localAccountId || 'see teams-read.mjs --whoami'})`);
