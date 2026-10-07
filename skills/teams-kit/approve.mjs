#!/usr/bin/env node
// The only path that sends as the owner: applies the owner's typed decision on a stored draft, no model.
// Usage and checks: README.md "Script reference" and GUARDRAILS.md.
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { spawnSync } from 'node:child_process';
import path from 'node:path';
import { fileURLToPath } from 'node:url';
import { connect, need, stateDir, fail } from './graph.mjs';
import { logComms } from './comms-log.mjs';
import { toHtml } from './fmt.mjs';

const MAX_AGE_H = 24;
const [verb, id] = process.argv.slice(2);
if (!['send', 'edit', 'skip', 'save'].includes(verb) || !/^D\d+$/.test(id || '')) fail('usage: approve.mjs send|edit|skip|save <Dn>', 2);
const file = path.join(stateDir(), 'drafts', `${id}.json`);
const here = path.dirname(fileURLToPath(import.meta.url));
const tell = (msg) => spawnSync('node', [path.join(here, 'teams-send-dm.mjs'), '--verbatim'], { input: `<p>${msg}</p>`, stdio: ['pipe', 'ignore', 'inherit'] });
const stop = (msg) => { tell(msg); process.exit(1); };

if (!existsSync(file)) stop(`I don't have a draft ${id}.`);
const d = JSON.parse(readFileSync(file, 'utf8'));
if (d.status !== 'pending') stop(`Draft ${id} is already ${d.status}.`);
if (Date.now() - Date.parse(d.created) > MAX_AGE_H * 3600e3) stop(`Draft ${id} is older than ${MAX_AGE_H}h; ask me for a fresh one.`);
const save = (status, extra = {}) => writeFileSync(file, JSON.stringify({ ...d, ...extra, status, decided: new Date().toISOString() }, null, 2));
if (verb === 'skip') { save('skipped'); logComms({ dir: 'draft', kind: 'skipped', draftId: id }); tell(`Skipped ${id}.`); process.exit(0); }
const text = verb === 'edit' ? readFileSync(0, 'utf8').trim() : d.text;
if (!text) stop(`Edit for ${id} was empty; nothing sent.`);
const isMail = d.kind === 'mail';
if (verb === 'save' && !isMail) stop(`${id} is a Teams draft; only email drafts can be saved to Outlook.`);

const OWNER = need('OWNER_UPN');
const { g } = await connect({ upn: OWNER, cache: need('OWNER_CACHE'),
  scopes: isMail ? ['Mail.Send', 'Mail.ReadWrite', 'User.Read'] : ['Chat.ReadWrite', 'ChatMessage.Send', 'User.Read'] });
try {
  if (isMail) {
    const rcpt = (a) => ({ emailAddress: { address: a } });
    const attachments = (d.attach || []).map((a) => {
      const buf = existsSync(a.path) ? readFileSync(a.path) : null;
      if (!buf || createHash('sha256').update(buf).digest('hex') !== a.sha256) throw new Error(`attachment ${a.name} is missing or changed since the draft`);
      return { '@odata.type': '#microsoft.graph.fileAttachment', name: a.name, contentBytes: buf.toString('base64') };
    });
    const html = toHtml(text);
    const recipients = { ...(d.to?.length ? { toRecipients: d.to.map(rcpt) } : {}), ...(d.cc?.length ? { ccRecipients: d.cc.map(rcpt) } : {}) };
    let msgId;
    if (d.replyTo) {   // reply in the original thread: keeps history and, unless overridden, recipients
      const r = await g(`/me/messages/${encodeURIComponent(d.replyTo)}/createReply`, { body: {} });
      await g(`/me/messages/${r.id}`, { method: 'PATCH', body: { body: { contentType: 'html', content: html + (r.body?.content || '') },
        ...(d.subject ? { subject: d.subject } : {}), ...recipients } });
      msgId = r.id;
    } else {
      msgId = (await g('/me/messages', { body: { subject: d.subject, body: { contentType: 'html', content: html }, ...recipients } })).id;
    }
    for (const a of attachments) await g(`/me/messages/${msgId}/attachments`, { body: a });
    if (verb === 'save') {
      save('saved-draft', { savedMessageId: msgId });
      logComms({ channel: 'mail', dir: 'draft', kind: 'saved-in-owner-drafts', draftId: id, to: d.to, cc: d.cc, subject: d.subject });
      tell(`Saved ${id} in your Outlook Drafts (not sent).`);
      process.exit(0);
    }
    await g(`/me/messages/${msgId}/send`, { body: {} });
    save('sent', { sentText: text });
    logComms({ channel: 'mail', dir: 'out', kind: 'as-owner', draftId: id, to: d.to, cc: d.cc, subject: d.subject, replyTo: d.replyTo, text });
    tell(`Emailed ${id} as you.`);
  } else {
    const sent = await g(`/chats/${d.chatId}/messages`, { body: { body: { contentType: 'html', content: toHtml(text) } } });
    save('sent', { sentText: text, sentMessageId: sent.id });
    logComms({ dir: 'out', kind: 'as-owner', draftId: id, chatId: d.chatId, to: d.to, messageId: sent.id, text });
    tell(`Sent ${id} as you.`);
  }
} catch (e) {
  logComms({ dir: 'out', kind: 'as-owner-error', draftId: id, error: e.message });
  stop(`Sending ${id} failed: ${e.message.slice(0, 120)}. Nothing went out.`);
}
