// Regression cases for link rendering: escaped HTML, raw markdown, italicised URLs.
import test from 'node:test';
import assert from 'node:assert/strict';
import { toHtml, ensureHtml } from './fmt.mjs';

const SP = 'https://example.sharepoint.com/personal/a_b_c/_layouts/15/Doc.aspx?sourcedoc=%7BX%7D&file=r2.docx&action=default';

test('literal <a href> inside markdown is kept as a link, not escaped', () => {
  const h = ensureHtml(`Ready.\n\n- <a href="${SP}">DOCX r2</a>: 41 pages`);
  assert.ok(!h.includes('&lt;a'), h);
  assert.ok(h.includes(`<a href="${SP.replace(/&/g, '&amp;')}">DOCX r2</a>`), h);
});

test('markdown link left inside HTML is converted', () => {
  const h = ensureHtml(`**Built.** Details<br>\nPR: [PR #149](https://github.com/o/r/pull/149)`);
  assert.ok(h.includes('<a href="https://github.com/o/r/pull/149">PR #149</a>'), h);
  assert.ok(h.includes('<b>Built.</b>') && !h.includes(']('), h);
});

test('underscores and asterisks in URLs are not italicised', () => {
  const u = 'https://x.com/_a_/b*c*d';
  const h = toHtml(`see [doc](${u}) and [two](${u})`);
  assert.equal((h.match(/<a href=/g) || []).length, 2, h);
  assert.ok(!/href="[^"]*</.test(h) && !h.includes('<i>'), h);
});

test('markdown link text still formats and escapes', () => {
  assert.equal(toHtml('[**PDF** <r2>](https://x.com/a)'), '<p><a href="https://x.com/a"><b>PDF</b> &lt;r2&gt;</a></p>');
});

test('plain HTML passes through untouched', () => {
  const h = `<p>Hi <a href="${SP.replace(/&/g, '&amp;')}">doc</a></p>`;
  assert.equal(ensureHtml(h), h);
});

test('non-link HTML in markdown is still escaped', () => {
  assert.equal(toHtml('use <script> here'), '<p>use &lt;script&gt; here</p>');
});

test('inline <b> in markdown text renders as bold, not literal tags', () => {
  const h = ensureHtml('Draft is <b>D4</b>.\n\n- <b>Option A</b>: direct or <i>workaround</i>');
  assert.ok(!h.includes('&lt;b&gt;') && !h.includes('&lt;i&gt;'), h);
  assert.ok(h.includes('<b>D4</b>') && h.includes('<li><b>Option A</b>'), h);
  assert.ok(toHtml('a <script>x</script> <b c="1">y</b>').includes('&lt;script&gt;'), 'other tags stay escaped');
});

test('markdown link whose URL contains parentheses stays one link', () => {
  const u = 'https://example.sharepoint.com/personal/a/Documents/Inputs%20(shared%20inputs)/x%20(y).csv';
  for (const h of [toHtml(`- [CSV](${u}): import file`), ensureHtml(`<p>see</p>\n[CSV](${u})`)]) {
    assert.ok(h.includes('<a href="https://example.sharepoint.com/personal/a/Documents/Inputs%20%28shared%20inputs%29/x%20%28y%29.csv">CSV</a>'), h);
    assert.ok(!h.includes('.csv)') && !h.includes(']('), h);
  }
});

test('plain links without parentheses are unchanged', () => {
  const h = toHtml(`[PR](https://github.com/o/r/pull/1)`);
  assert.ok(h.includes('<a href="https://github.com/o/r/pull/1">PR</a>'), h);
});
