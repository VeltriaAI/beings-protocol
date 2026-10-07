#!/usr/bin/env node
// Apply triage decisions (none | react | reply) read from stdin; exit 1 if any failed.
// Usage: README.md "Script reference".
import { readFileSync, writeFileSync, existsSync } from 'node:fs';
import path from 'node:path';
import { connect, need, stateDir, standby, fail } from './graph.mjs';
import { logComms } from './comms-log.mjs';
import { replyRef } from './reply-ref.mjs';
import { toHtml } from './fmt.mjs';
import { findSecrets } from './secrets.mjs';

if (standby()) fail('standby host: acknowledgements disabled', 3);
const ACKED = path.join(stateDir(), 'acked-ids.txt');
const EMOJI = new Set(['👍', '❤️', '😆', '😮', '🙏', '🔥', '✅', '🎉', '👀', '💯', '🚀', '🙌', '👌', '😊', '💪']);
// People who asked for words instead of reactions (one sender object id per line).
const NO_REACT_F = path.join(stateDir(), 'no-react.txt');
const NO_REACT = new Set(existsSync(NO_REACT_F) ? readFileSync(NO_REACT_F, 'utf8').split('\n').map((s) => s.split('#')[0].trim()).filter(Boolean) : []);

const input = JSON.parse(readFileSync(0, 'utf8') || '{}');
const byMsg = new Map((input.actions || []).map((a) => [a.messageId, a]));
const acked = new Set(existsSync(ACKED) ? readFileSync(ACKED, 'utf8').split('\n').filter(Boolean) : []);
const todo = (input.messages || []).filter((m) => m.messageId && m.addressedBy !== 'reaction' && !acked.has(m.messageId));
if (!todo.length) process.exit(0);

const { g } = await connect({ upn: need('BEING_UPN'), scopes: ['Chat.ReadWrite', 'ChatMessage.Send', 'User.Read'] });
let failed = 0;
for (const m of todo) {
  logComms({ dir: 'in', chatId: m.chatId, chatType: m.chatType, topic: m.topic, from: m.from, at: m.at,
    messageId: m.messageId, text: m.text ?? m.preview, attachments: m.attachments });
  const d = byMsg.get(m.messageId) || { action: m.chatType === 'oneOnOne' ? 'react' : 'none', fallback: true };
  if (d.action === 'react' && NO_REACT.has(m.fromId)) Object.assign(d, { action: 'reply', text: d.text?.trim() || 'Got it, thanks.' });
  const leaked = d.action === 'reply' ? findSecrets(d.text) : [];
  if (leaked.length) {   // a triage reply that quotes .env or a credential is dropped; the work run still answers
    logComms({ dir: 'ack', kind: 'blocked-secret', chatId: m.chatId, messageId: m.messageId, error: leaked.join(', ') });
    Object.assign(d, { action: 'none', text: '' });
  }
  try {
    if (d.action === 'react') {
      await g(`/chats/${m.chatId}/messages/${m.messageId}/setReaction`, { body: { reactionType: EMOJI.has(d.emoji) ? d.emoji : '👍' } });
      logComms({ dir: 'ack', kind: d.fallback ? 'reaction-fallback' : 'reaction', chatId: m.chatId, messageId: m.messageId, to: m.from });
    } else if (d.action === 'reply' && d.text?.trim()) {
      const plain = { body: { contentType: 'html', content: toHtml(d.text.trim()) } };
      let body = plain;
      try {
        const ref = await replyRef(g, m.chatId, m.messageId);
        body = { body: { contentType: 'html', content: ref.tag + plain.body.content }, attachments: [ref.attachment] };
      } catch (e) { console.error(`quote ${m.messageId} unavailable: ${e.message}`); }
      const sent = await g(`/chats/${m.chatId}/messages`, { body })
        .catch((e) => { if (body === plain) throw e; console.error(`quoted reply rejected (${e.message}); sending plain`); return g(`/chats/${m.chatId}/messages`, { body: plain }); });
      logComms({ dir: 'out', kind: 'ack-reply', chatId: m.chatId, messageId: sent.id, replyTo: m.messageId, to: m.from, text: d.text.trim() });
    } else {
      logComms({ dir: 'ack', kind: 'none', chatId: m.chatId, messageId: m.messageId, to: m.from });
    }
    acked.add(m.messageId);
  } catch (e) {
    failed++;
    logComms({ dir: 'ack', kind: 'error', chatId: m.chatId, messageId: m.messageId, error: e.message });
    console.error(`ack ${m.messageId} failed: ${e.message}`);
  }
}
writeFileSync(ACKED, [...acked].slice(-5000).join('\n') + '\n');
process.exit(failed ? 1 : 0);
