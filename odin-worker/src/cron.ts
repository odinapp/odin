import type { Env } from './types';
import { listCleanupEntries, deleteCleanupEntry } from './lib/kv';

export async function runCleanup(env: Env): Promise<void> {
  const entries = await listCleanupEntries(env.KV_METADATA);
  const now = Date.now();

  for (const entry of entries) {
    const expiresAt = new Date(entry.expiresAt).getTime();
    if (expiresAt < now) {
      // Delete R2 object — do NOT look up metadata KV, it will already be gone (24h TTL expired)
      await env.R2_BUCKET.delete(entry.r2Key);
      await deleteCleanupEntry(env.KV_METADATA, entry.token);
    }
  }
}
