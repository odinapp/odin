import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleRedirect } from '../handlers/redirect';
import { setMetadata } from '../lib/kv';
import type { UploadMetadata } from '../lib/kv';

const SAMPLE: UploadMetadata = {
  r2Key: 'sh000001/hello.txt',
  filename: 'hello.txt',
  size: 42,
  uploadedAt: '2026-03-24T00:00:00.000Z',
  expiresAt: '2026-03-25T00:00:00.000Z',
  deleteToken: 'yyyyyyyyyyyyyyyy',
};

describe('GET /d/:token', () => {
  it('returns 404 when token not found', async () => {
    const req = new Request('https://example.com/d/notfound');
    const res = await handleRedirect(req, env);
    expect(res.status).toBe(404);
  });

  it('serves file bytes directly (no redirect)', async () => {
    const content = 'short url file content';
    await env.R2_BUCKET.put('sh000001/hello.txt', new TextEncoder().encode(content));
    const metadata = { ...SAMPLE, size: content.length };
    await setMetadata(env.KV_METADATA, 'sh000001', metadata);
    const req = new Request('https://example.com/d/sh000001');
    const res = await handleRedirect(req, env);
    expect(res.status).toBe(200);
    // Must match download handler headers exactly
    expect(res.headers.get('Filename')).toBe('hello.txt');
    expect(res.headers.get('Content-Disposition')).toContain('hello.txt');
    expect(res.headers.get('Content-Length')).toBe(String(content.length));
    expect(await res.text()).toBe(content);
  });
});
