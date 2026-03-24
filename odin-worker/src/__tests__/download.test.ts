import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleDownload } from '../handlers/download';
import { setMetadata } from '../lib/kv';
import type { UploadMetadata } from '../lib/kv';

const SAMPLE: UploadMetadata = {
  r2Key: 'dl000001/report.txt',
  filename: 'report.txt',
  size: 11,
  uploadedAt: '2026-03-24T00:00:00.000Z',
  expiresAt: '2026-03-25T00:00:00.000Z',
  deleteToken: 'xxxxxxxxxxxxxxxx',
};

async function seedFile(token: string, filename: string, content: string) {
  const r2Key = `${token}/${filename}`;
  await env.R2_BUCKET.put(r2Key, new TextEncoder().encode(content));
  await setMetadata(env.KV_METADATA, token, {
    r2Key,
    filename,
    size: content.length,
    uploadedAt: new Date().toISOString(),
    expiresAt: new Date(Date.now() + 86400000).toISOString(),
    deleteToken: 'xxxxxxxxxxxxxxxx',
  });
}

describe('GET /api/v1/file/download/', () => {
  it('returns 404 for unknown token', async () => {
    const req = new Request('https://example.com/api/v1/file/download/?token=missing');
    const res = await handleDownload(req, env);
    expect(res.status).toBe(404);
  });

  it('returns file bytes with correct headers', async () => {
    await seedFile('dl000001', 'report.txt', 'download me');
    const req = new Request('https://example.com/api/v1/file/download/?token=dl000001');
    const res = await handleDownload(req, env);
    expect(res.status).toBe(200);
    expect(res.headers.get('Content-Type')).toBe('application/octet-stream');
    expect(res.headers.get('Filename')).toBe('report.txt');
    expect(res.headers.get('Content-Disposition')).toContain('report.txt');
    expect(res.headers.get('Content-Length')).toBe('11');
    const text = await res.text();
    expect(text).toBe('download me');
  });

  it('accepts a full /d/ URL as the token query param', async () => {
    await seedFile('dl000001', 'report.txt', 'download me');
    const tokenUrl = encodeURIComponent('https://odin-worker.workers.dev/d/dl000001');
    const req = new Request(`https://example.com/api/v1/file/download/?token=${tokenUrl}`);
    const res = await handleDownload(req, env);
    expect(res.status).toBe(200);
    const text = await res.text();
    expect(text).toBe('download me');
  });
});
