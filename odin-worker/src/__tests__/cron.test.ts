import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { runCleanup } from '../cron';
import { setCleanupEntry } from '../lib/kv';

describe('runCleanup', () => {
  it('deletes R2 object and cleanup entry for expired uploads', async () => {
    const token = 'cr000001';
    await env.R2_BUCKET.put(`${token}/file.txt`, new TextEncoder().encode('x'));
    const past = new Date(Date.now() - 1000).toISOString(); // already expired
    await setCleanupEntry(env.KV_METADATA, token, { token, r2Key: `${token}/file.txt`, expiresAt: past });

    await runCleanup(env);

    expect(await env.R2_BUCKET.get(`${token}/file.txt`)).toBeNull();
    expect(await env.KV_METADATA.get(`cleanup:${token}`)).toBeNull();
  });

  it('does NOT delete R2 object for unexpired uploads', async () => {
    const token = 'cr000002';
    await env.R2_BUCKET.put(`${token}/file.txt`, new TextEncoder().encode('y'));
    const future = new Date(Date.now() + 86400000).toISOString();
    await setCleanupEntry(env.KV_METADATA, token, { token, r2Key: `${token}/file.txt`, expiresAt: future });

    await runCleanup(env);

    expect(await env.R2_BUCKET.get(`${token}/file.txt`)).not.toBeNull();
    expect(await env.KV_METADATA.get(`cleanup:${token}`)).not.toBeNull();
  });
});
