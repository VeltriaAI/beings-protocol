#!/usr/bin/env node
// Cheap Teams poll: new messages addressed to the Being since a watermark (no model).
// Exit codes and env: README.md "Script reference".
import { connect, need, fail, strip } from './graph.mjs';

const since = process.argv[2];
if (!since) fail('usage: teams-detect.mjs <ISO8601-watermark>');
const { g, me } = await connect({ upn: need('BEING_UPN'), scopes: ['Chat.Read', 'User.Read'] });
const SELF = me.id;
const OWNER = process.env.OWNER_OID || '';
const NAME_RE = new RegExp(`\\b${need('BEING_NAME').replace(/[.*+?^${}()|[\]\\]/g, '\\$&')}\\b`, 'i');
const EMO = { like: '👍', heart: '❤️', laugh: '😆', surprised: '😮', sad: '😢', angry: '😡' };

const members = new Map();   // chatId -> Map(userId -> displayName)
async function nameOf(id, chatId) {
  if (!id) return 'unknown';
  if (!members.has(chatId)) {
    const m = new Map();
    try { for (const x of (await g(`/chats/${chatId}/members`)).value ?? []) if (x.userId) m.set(x.userId, x.displayName || x.userId.slice(0, 8)); } catch {}
    members.set(chatId, m);
  }
  return members.get(chatId).get(id) || id.slice(0, 8);
}

try {
  // One watermark covers every chat, so every tick sweeps every chat.
  const chats = (await g('/me/chats?$top=50&$select=id,topic,chatType')).value ?? [];
  const hits = [];
  let transient = false;
  // Graph has no createdDateTime filter for chat messages: fetch the newest few and compare locally.
  await Promise.all(chats.map(async (c) => {
    try {
      for (const m of (await g(`/chats/${c.id}/messages?$top=8`)).value ?? []) {
        // Reactions to the Being's own messages count as input (a 👍 on a question is an answer).
        if (m.from?.user?.id === SELF && !m.deletedDateTime) {
          for (const r of m.reactions ?? []) {
            if (!r.createdDateTime || r.createdDateTime <= since || r.user?.user?.id === SELF) continue;
            if (c.chatType !== 'oneOnOne' && r.user?.user?.id !== OWNER) continue;   // group likes are not a cue
            hits.push({ addressedBy: 'reaction', chatId: c.id, topic: c.topic ?? '(direct)', chatType: c.chatType,
              from: r.user?.user?.displayName ?? await nameOf(r.user?.user?.id, c.id), fromId: r.user?.user?.id, at: r.createdDateTime,
              preview: `${r.displayName || EMO[r.reactionType] || r.reactionType} on my message [${m.id}]: "${strip(m.body?.content).slice(0, 100)}"` });
          }
          continue;
        }
        if (!m.createdDateTime || m.createdDateTime <= since) continue;
        if (m.messageType !== 'message' || m.deletedDateTime || !m.from?.user?.id) continue;   // system events, notices
        if (m.from.user.id === SELF) continue;   // never answer yourself: that is the loop
        const html = m.body?.content ?? '';
        const text = strip(html).replace(/\s+/g, ' ');
        const attachments = [
          ...(m.attachments ?? []).filter((a) => a.contentType === 'reference' && a.contentUrl).map((a) => ({ kind: 'file', name: a.name ?? '(unnamed)', url: a.contentUrl })),
          ...[...html.matchAll(/<img[^>]+src="([^"]+)"/gi)].map((x) => ({ kind: 'image', name: 'inline image', url: x[1] })),
        ];
        // Wake the model only for messages FOR the Being: a 1:1, an @mention, or its name in the text.
        const addressed = c.chatType === 'oneOnOne' || m.mentions?.some((x) => x.mentioned?.user?.id === SELF) || NAME_RE.test(text);
        if (!addressed) continue;
        hits.push({ addressedBy: c.chatType === 'oneOnOne' ? 'direct-chat' : 'named-or-mentioned',
          chatId: c.id, topic: c.topic ?? '(direct)', chatType: c.chatType, from: m.from.user.displayName ?? 'unknown',
          fromId: m.from.user.id, at: m.createdDateTime, messageId: m.id, preview: text.slice(0, 160), text,
          ...(attachments.length ? { attachments } : {}) });
      }
    } catch (e) {
      // One unreadable chat must not blind the sweep; a transient error must hold the watermark.
      console.error(`chat ${c.id.slice(0, 30)}: ${e.message}`);
      if (!/^40[34] /.test(e.message)) transient = true;
    }
  }));
  if (transient && !hits.length) process.exit(1);
  if (!hits.length) process.exit(0);
  hits.sort((a, b) => a.at.localeCompare(b.at));
  console.log(JSON.stringify({ since, count: hits.length, messages: hits }, null, 2));
  process.exit(transient ? 11 : 10);
} catch (e) {
  fail(`detect failed: ${e.message}`);
}
