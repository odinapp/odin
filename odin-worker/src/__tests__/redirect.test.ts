import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleRedirect } from '../handlers/redirect';

describe('GET /d/:token', () => {
  it('returns 404 when token not found', async () => {
    const req = new Request('https://example.com/d/notfound');
    const res = await handleRedirect(req, env);
    expect(res.status).toBe(404);
  });

  it('returns 404 even when token exists', async () => {
    const req = new Request('https://example.com/d/sh000001');
    const res = await handleRedirect(req, env);
    expect(res.status).toBe(404);
  });
});
