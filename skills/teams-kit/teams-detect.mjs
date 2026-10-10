#!/usr/bin/env node
// Cheap Teams poll: new messages addressed to the Being since a watermark (no model).
// Exit codes and env: README.md "Script reference".
import { connect, need, fail, strip } from './graph.mjs';

const since = process.argv[2];
if (!since) fail('usage: teams-detect.mjs <ISO8601-watermark>');
const { g, me } = await connect({ upn: need('BEING_UPN'), scopes: ['Chat.Read', 'User.Read'] });
const SELF = me.id;
const OWNER = process.env.OWNER_OID || '';
const esc = (x) => x.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
const list = (k) => (process.env[k] || '').split(',').map((x) => x.trim()).filter(Boolean);
// Name or alias as a word wakes the Being; stop-list phrases ("Nova Scotia") are removed first (README "Detection limits").
const NAME_RE = new RegExp(`\\b(?:${[need('BEING_NAME'), ...list('BEING_NAME_ALIASES')].map(esc).join('|')})\\b`, 'i');
const STOP = list('BEING_NAME_STOPLIST').map((x) => new RegExp(esc(x), 'gi'));
const named = (t) => NAME_RE.test(STOP.reduce((s, re) => s.replace(re, ' '), t));
// Sweep limits (README "Detection limits"): most recently active chats first, newest messages per chat.
const int = (k, d, max) => Math.min(max, Math.max(1, parseInt(process.env[k] || '', 10) || d));
const MAX_CHATS = int('BEING_DETECT_CHATS', 50, 1000), PER_CHAT = int('BEING_DETECT_MESSAGES', 8, 50);
const MAX_PAGES = int('BEING_DETECT_PAGES', 5, 20);
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
  // One watermark covers every chat, so every tick sweeps every chat (up to MAX_CHATS, paged).
  const base = '/me/chats?$top=50&$select=id,topic,chatType';
  let r = await g(`${base}&$orderby=lastMessagePreview/createdDateTime desc`).catch(() => g(base));   // unordered if $orderby is refused
  const chats = [...(r.value ?? [])];
  while (r['@odata.nextLink'] && chats.length < MAX_CHATS) { r = await g(r['@odata.nextLink']); chats.push(...(r.value ?? [])); }
  chats.splice(MAX_CHATS);
  const hits = [];
  let transient = false;
  // Graph has no createdDateTime filter for chat messages: fetch the newest few and compare locally.
  await Promise.all(chats.map(async (c) => {
    try {
      // A burst can fill the first page: read further back until a message at or before the watermark (bounded).
      let r = await g(`/chats/${c.id}/messages?$top=${PER_CHAT}`);
      const page = [...(r.value ?? [])];
      for (let n = 1; n < MAX_PAGES && r['@odata.nextLink'] && page.length && page.every((m) => (m.createdDateTime || '') > since); n++) {
        r = await g(r['@odata.nextLink']); page.push(...(r.value ?? []));
      }
      if (r['@odata.nextLink'] && page.length && page.every((m) => (m.createdDateTime || '') > since)) {
        console.error(`chat ${c.id.slice(0, 30)}: ${page.length}+ new messages since the last sweep; older ones may be missed (raise BEING_DETECT_PAGES)`);
      }
      for (const m of page) {
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
        const addressed = c.chatType === 'oneOnOne' || m.mentions?.some((x) => x.mentioned?.user?.id === SELF) || named(text);
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
