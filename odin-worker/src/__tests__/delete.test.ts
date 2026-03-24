import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleDelete } from '../handlers/delete';
import { setMetadata, setCleanupEntry, getMetadata } from '../lib/kv';

const DELETE_TOKEN = 'mysecret1234abcd';

async function seedUpload(token: string) {
  const r2Key = `${token}/file.txt`;
  await env.R2_BUCKET.put(r2Key, new TextEncoder().encode('data'));
  await setMetadata(env.KV_METADATA, token, {
    r2Key,
    filename: 'file.txt',
    size: 4,
    uploadedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
    deleteToken: DELETE_TOKEN,
  });
  await setCleanupEntry(env.KV_METADATA, token, {
    token,
    r2Key,
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
  });
}

describe('DELETE /delete/:token', () => {
  it('returns 404 for unknown token', async () => {
    const req = new Request('https://example.com/delete/notexist?secret=anything', { method: 'DELETE' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(404);
  });

  it('returns 403 when secret does not match', async () => {
    await seedUpload('del00001');
    const req = new Request('https://example.com/delete/del00001?secret=wrongsecret', { method: 'DELETE' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(403);
  });

  it('deletes R2 object, KV metadata, and cleanup entry on valid DELETE', async () => {
    await seedUpload('del00002');
    const req = new Request(`https://example.com/delete/del00002?secret=${DELETE_TOKEN}`, { method: 'DELETE' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(200);
    // Verify KV metadata gone
    expect(await getMetadata(env.KV_METADATA, 'del00002')).toBeNull();
    // Verify R2 object gone
    expect(await env.R2_BUCKET.get('del00002/file.txt')).toBeNull();
    // Verify cleanup entry gone
    const cleanupRaw = await env.KV_METADATA.get('cleanup:del00002');
    expect(cleanupRaw).toBeNull();
  });

  it('also accepts GET method for browser-friendly delete', async () => {
    await seedUpload('del00003');
    const req = new Request(`https://example.com/delete/del00003?secret=${DELETE_TOKEN}`, { method: 'GET' });
    const res = await handleDelete(req, env);
    expect(res.status).toBe(200);
  });
});
