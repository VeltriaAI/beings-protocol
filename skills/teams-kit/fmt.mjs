// Light markdown → Teams HTML: **bold**, *italic*/_italic_, `code`, "- " / "1. " lists, [text](url), paragraphs.
// Input is escaped first, so only these constructs (and literal <a href> links) become markup.
const esc = (s) => s.replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;');

// URL part allows one level of balanced parens, e.g. SharePoint names like "x (y).csv".
const URL_RE = String.raw`https?:\/\/(?:[^\s()]|\([^\s()]*\))+`;
const LINK = new RegExp(String.raw`\[([^\]]+)\]\((${URL_RE})\)|<a\s[^>]*?href=["'](https?:\/\/[^"']+)["'][^>]*>(.*?)<\/a>`, 'gi');
const href = (u) => u.replace(/&amp;/g, '&').replace(/&/g, '&amp;').replace(/"/g, '%22').replace(/\(/g, '%28').replace(/\)/g, '%29');

const format = (s) => s
  .replace(/`([^`]+)`/g, '<code>$1</code>')
  .replace(/\*\*([^*]+)\*\*/g, '<b>$1</b>')
  .replace(/(^|[^*\w])\*([^*\n]+)\*(?!\w)/g, '$1<i>$2</i>')
  .replace(/(^|[^\w])_([^_\n]+)_(?!\w)/g, '$1<i>$2</i>');

// Bare <b>/<i>/<code>/<br> written inline stay markup instead of showing as literal tags.
const SIMPLE = /&lt;(\/?)(b|i|code|br)&gt;/g;

// Links (markdown or a literal <a href>) are set aside first so URLs are never escaped or italicised.
const inline = (s) => {
  const links = [];
  const keep = (_, mt, mu, hu, ht) => `\u0000${links.push(`<a href="${href(mu || hu)}">${mt != null ? format(esc(mt)) : ht.replace(/<[^>]+>/g, '')}</a>`) - 1}\u0000`;
  return format(esc(s.replace(LINK, keep))).replace(SIMPLE, '<$1$2>').replace(/\u0000(\d+)\u0000/g, (_, i) => links[i]);
};

export function toHtml(text) {
  // Text lines (incl. "• " bullets) share one <p> joined by <br>; a blank line is one empty line.
  // "- " / "1. " runs still become lists.
  const out = []; let list = null, para = null;
  const closeList = () => { if (list) { out.push(`</${list}>`); list = null; } };
  const closePara = () => {
    if (para) { while (para.length && para.at(-1) === '') para.pop(); if (para.length) out.push(`<p>${para.join('<br>')}</p>`); para = null; }
  };
  for (const line of text.trim().split('\n')) {
    const b = /^\s*[-*]\s+/.test(line), n = /^\s*\d+[.)]\s+/.test(line);
    if (b || n) {
      closePara();
      const tag = b ? 'ul' : 'ol';
      if (list !== tag) { closeList(); out.push(`<${tag}>`); list = tag; }
      out.push(`<li>${inline(line.replace(/^\s*([-*]|\d+[.)])\s+/, ''))}</li>`);
    } else if (!line.trim()) {
      closeList();
      if (para && para.at(-1) !== '') para.push('');
    } else {
      closeList();
      if (!para) para = [];
      para.push(inline(line.trim()));
    }
  }
  closeList(); closePara();
  return out.join('');
}

// Markdown or plain text → HTML; text that already carries block markup stays HTML.
// Markdown links/bold left inside HTML are still converted, so a mixed body never shows raw [name](url).
const BLOCK = /<(p|ul|ol|br|div|table|blockquote|hr|attachment)\b[^>]*>/i;
export const ensureHtml = (text) => BLOCK.test(text)
  ? text.replace(new RegExp(String.raw`\[([^\]]+)\]\((${URL_RE})\)`, 'g'), (_, t, u) => `<a href="${href(u)}">${t}</a>`).replace(/\*\*([^*<]+)\*\*/g, '<b>$1</b>')
  : toHtml(text);
