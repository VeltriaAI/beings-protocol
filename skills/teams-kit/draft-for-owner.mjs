#!/usr/bin/env node
// Stage a draft written on the owner's behalf and send it to the owner for approval (approve.mjs sends).
// Usage: README.md "Script reference".
import { readFileSync, writeFileSync, existsSync, mkdirSync, statSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { stateDir, fail } from './graph.mjs';
import { logComms } from './comms-log.mjs';
import { toHtml } from './fmt.mjs';

const args = process.argv.slice(2);
const opt = (f) => { const i = args.indexOf(f); return i === -1 ? '' : (args[i + 1] ?? ''); };
const isMail = args.includes('--mail');
const chatId = opt('--chat'), to = opt('--to'), re = opt('--re'), cc = opt('--cc'), subject = opt('--subject'), replyTo = opt('--reply-to');
const attach = opt('--attach').split(',').map((x) => x.trim()).filter(Boolean).map((f) => {
  if (!path.isAbsolute(f) || !existsSync(f) || statSync(f).size >= 3 * 1024 * 1024) fail(`attachment missing, relative or >= 3 MB: ${f}`, 2);
  return { path: f, name: path.basename(f), size: statSync(f).size, sha256: createHash('sha256').update(readFileSync(f)).digest('hex') };
});
const text = readFileSync(0, 'utf8').trim();
if (!text || (isMail ? !(to || replyTo) || (!subject && !replyTo) : !chatId)) {
  fail('usage: --chat <chatId> --to <label> [--re <msg>] < draft.md | --mail --to a,b [--cc c] --subject S [--reply-to <id>] [--attach /abs/f] < draft.md', 2);
}

const DIR = path.join(stateDir(), 'drafts');
mkdirSync(DIR, { recursive: true });
const nf = path.join(DIR, 'next-id');
const n = existsSync(nf) ? parseInt(readFileSync(nf, 'utf8'), 10) : 1;
writeFileSync(nf, String(n + 1));
const id = `D${n}`;
const list = (s) => s.split(',').map((x) => x.trim()).filter(Boolean);
const draft = isMail ? { id, kind: 'mail', to: list(to), cc: list(cc), subject, replyTo, re, text, attach }
  : { id, kind: 'teams', chatId, to: to || 'them', re, text };
writeFileSync(path.join(DIR, `${id}.json`), JSON.stringify({ ...draft, status: 'pending', created: new Date().toISOString() }, null, 2));

const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');
const head = isMail
  ? `<p><b>Draft ${id}</b>: email as you${replyTo ? ' (reply in thread)' : ''} to <b>${esc(draft.to.join(', ') || 'the original sender')}</b>`
    + (draft.cc.length ? ` cc ${esc(draft.cc.join(', '))}` : '') + '</p>' + (subject ? `<p><i>Subject:</i> ${esc(subject)}</p>` : '')
    + (attach.length ? `<p><i>Attachments:</i> ${esc(attach.map((a) => `${a.name} (${Math.round(a.size / 1024)} KB)`).join(', '))}</p>` : '')
  : `<p><b>Draft ${id}</b>: reply as you to <b>${esc(draft.to)}</b></p>`;
const html = head + (re ? `<p><i>They wrote:</i> “${esc(re.slice(0, 300))}”</p>` : '') + '<hr>' + toHtml(text) + '<hr>'
  + `<p>Reply <b>send ${id}</b> · <b>edit ${id} &lt;new text&gt;</b> · <b>skip ${id}</b>${isMail ? ` · <b>save ${id}</b>` : ''}</p>`;
const here = path.dirname(fileURLToPath(import.meta.url));
const r = spawnSync('node', [path.join(here, 'teams-send-dm.mjs'), '--verbatim'], { input: html, stdio: ['pipe', 'inherit', 'inherit'] });
if (r.status !== 0) fail(`draft ${id} stored but not delivered to the owner`);
logComms({ channel: isMail ? 'mail' : 'teams', dir: 'draft', kind: 'for-owner', draftId: id, chatId, to: draft.to, subject, text });
console.log(id);
