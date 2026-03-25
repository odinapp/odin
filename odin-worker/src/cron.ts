import type { Env } from './types';
import { listCleanupEntries, deleteCleanupEntry } from './lib/kv';

export async function runCleanup(env: Env): Promise<void> {
  const entries = await listCleanupEntries(env.KV_METADATA);
  const now = Date.now();

  for (const entry of entries) {
    const expiresAt = new Date(entry.expiresAt).getTime();
    if (expiresAt >= now) continue;

    try {
      // R2 delete is idempotent — safe if object was already removed
      await env.R2_BUCKET.delete(entry.r2Key);
      await deleteCleanupEntry(env.KV_METADATA, entry.token);
    } catch (err) {
      // Log and continue — don't let one failure abort the rest of the cleanup pass
      console.error(`[cleanup] Failed to clean up token ${entry.token}:`, err);
    }
  }
}
