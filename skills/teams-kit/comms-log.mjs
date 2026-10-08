// Append-only JSONL log of every message the Being receives, acknowledges, drafts or sends.
import { appendFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';

const LOG = process.env.BEING_COMMS_LOG || path.join(process.env.BEING_STATE_DIR || '.', 'comms.jsonl');

export function logComms(entry) {
  if (LOG === '/dev/null') return;
  mkdirSync(path.dirname(LOG), { recursive: true });
  appendFileSync(LOG, JSON.stringify({ loggedAt: new Date().toISOString(), ...entry }) + '\n');
}
