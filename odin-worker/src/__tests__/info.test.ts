import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleInfo } from '../handlers/info';
import { setMetadata } from '../lib/kv';
import type { UploadMetadata } from '../lib/kv';

const SAMPLE: UploadMetadata = {
  r2Key: 'tok00001/file.txt',
  filename: 'file.txt',
  size: 42,
  uploadedAt: '2026-03-24T00:00:00.000Z',
  expiresAt: '2026-03-25T00:00:00.000Z',
  deleteToken: 'xxxxxxxxxxxxxxxx',
};

describe('GET /api/v1/file/info/', () => {
  it('returns 404 for unknown token', async () => {
    const req = new Request('https://example.com/api/v1/file/info/?token=notexist');
    const res = await handleInfo(req, env);
    expect(res.status).toBe(404);
  });

  it('returns FilesMetadata shape for a known token', async () => {
    await setMetadata(env.KV_METADATA, 'tok00001', SAMPLE);
    const req = new Request('https://example.com/api/v1/file/info/?token=tok00001');
    const res = await handleInfo(req, env);
    expect(res.status).toBe(200);
    const body = await res.json() as Record<string, unknown>;
    expect(body.basePath).toBeNull();
    expect(Array.isArray(body.files)).toBe(true);
    expect((body.files as { path: string }[])[0].path).toBe('file.txt');
    expect(body.totalFileSize).toBe('42');
  });

  it('accepts a full /d/ URL as the token query param', async () => {
    await setMetadata(env.KV_METADATA, 'tok00001', SAMPLE);
    const tokenUrl = encodeURIComponent('https://odin-worker.workers.dev/d/tok00001');
    const req = new Request(`https://example.com/api/v1/file/info/?token=${tokenUrl}`);
    const res = await handleInfo(req, env);
    expect(res.status).toBe(200);
  });
});
