import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleConfig } from '../handlers/config';

describe('GET /api/v1/config/', () => {
  it('returns 200 with all required fields and exact string values', async () => {
    const req = new Request('https://example.com/api/v1/config/');
    const res = await handleConfig(req, env);
    expect(res.status).toBe(200);

    const body = await res.json() as Record<string, unknown>;

    // home — exact values consumed by Flutter HomeConfig deserialiser
    const home = body.home as Record<string, string>;
    expect(home.title).toBe('Odin');
    expect(home.primaryButtonText).toBe('Send files');
    expect(home.secondaryButtonText).toBe('Receive files');

    // upload — exact values consumed by Flutter UploadConfig deserialiser (7 required fields)
    const upload = body.upload as Record<string, string>;
    expect(upload.title).toBe('Uploading');
    expect(upload.description).toBe('Your files are being uploaded');
    expect(upload.backButtonText).toBe('Back');
    expect(upload.cancelDefaultText).toBe('Cancel');
    expect(upload.errorButtonText).toBe('Retry');
    expect(upload.errorDefaultText).toBe('Upload failed');
    expect(upload.successDefaultText).toBe('Upload complete');

    // token — exact values consumed by Flutter TokenConfig deserialiser (5 required fields)
    const token = body.token as Record<string, string>;
    expect(token.title).toBe('Receive files');
    expect(token.description).toBe('Enter the token to download your files');
    expect(token.textFieldHintText).toBe('Enter token');
    expect(token.backButtonText).toBe('Back');
    expect(token.primaryButtonText).toBe('Download');
  });
});
