import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleDownload } from '../handlers/download';
import { setMetadata } from '../lib/kv';
import { wrapEncryptionKey } from '../lib/keywrap';

function uint32(value: number): Uint8Array {
  const data = new DataView(new ArrayBuffer(4));
  data.setUint32(0, value, false);
  return new Uint8Array(data.buffer);
}

async function buildEncryptedContainer(
  payloadText: string,
): Promise<{ bytes: Uint8Array; keyB64: string }> {
  const key = Uint8Array.from({ length: 32 }, (_, i) => i + 1);
  const nonce = Uint8Array.from({ length: 12 }, (_, i) => i + 11);
  const manifest = {
    name: 'files.zip',
    size: payloadText.length,
    zipped: true,
    files: [{ path: 'docs/a.txt', size: payloadText.length }],
    fileCount: 1,
  };
  const manifestBytes = new TextEncoder().encode(JSON.stringify(manifest));
  const payloadBytes = new TextEncoder().encode(payloadText);
  const plain = new Uint8Array(4 + manifestBytes.length + payloadBytes.length);
  plain.set(uint32(manifestBytes.length), 0);
  plain.set(manifestBytes, 4);
  plain.set(payloadBytes, 4 + manifestBytes.length);

  const cryptoKey = await crypto.subtle.importKey(
    'raw',
    key,
    'AES-GCM',
    false,
    ['encrypt'],
  );
  const cipherWithTag = new Uint8Array(
    await crypto.subtle.encrypt({ name: 'AES-GCM', iv: nonce }, cryptoKey, plain),
  );
  const cipher = cipherWithTag.slice(0, cipherWithTag.length - 16);
  const tag = cipherWithTag.slice(cipherWithTag.length - 16);

  const magic = new TextEncoder().encode('ODINENC2');
  const out = new Uint8Array(
    magic.length + 1 + nonce.length + 4 + cipher.length + tag.length,
  );
  let offset = 0;
  out.set(magic, offset);
  offset += magic.length;
  out[offset++] = 2;
  out.set(nonce, offset);
  offset += nonce.length;
  out.set(uint32(cipher.length), offset);
  offset += 4;
  out.set(cipher, offset);
  offset += cipher.length;
  out.set(tag, offset);

  const keyB64 = btoa(String.fromCharCode(...key))
    .replaceAll('+', '-')
    .replaceAll('/', '_')
    .replaceAll('=', '');
  return { bytes: out, keyB64 };
}

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
    expect(res.headers.get('X-Odin-Encrypted')).toBe('false');
    const text = await res.text();
    expect(text).toBe('download me');
  });

  it('decrypts encrypted container when wrapped key exists', async () => {
    const token = 'dl00enc1';
    const { bytes, keyB64 } = await buildEncryptedContainer('zip-bytes');
    const wrappedKey = await wrapEncryptionKey(keyB64, env.ENCRYPTION_METADATA_KEY);
    const r2Key = `${token}/opaque.odin`;

    await env.R2_BUCKET.put(r2Key, bytes);
    await setMetadata(env.KV_METADATA, token, {
      r2Key,
      filename: 'opaque.odin',
      size: bytes.length,
      uploadedAt: new Date().toISOString(),
      expiresAt: new Date(Date.now() + 86400000).toISOString(),
      deleteToken: 'xxxxxxxxxxxxxxxx',
      wrappedEncryptionKey: wrappedKey,
      encrypted: true,
      isArchive: true,
      fileCount: 1,
    });

    const req = new Request(`https://example.com/api/v1/file/download/?token=${token}`);
    const res = await handleDownload(req, env);
    expect(res.status).toBe(200);
    expect(res.headers.get('Filename')).toBe('files.zip');
    expect(res.headers.get('X-Odin-Archive')).toBe('true');
    expect(res.headers.get('X-Odin-Encrypted')).toBe('true');
    expect(await res.text()).toBe('zip-bytes');
  });

  it('rejects URL-style token query param', async () => {
    await seedFile('dl000001', 'report.txt', 'download me');
    const tokenUrl = encodeURIComponent('https://odin-worker.workers.dev/d/dl000001');
    const req = new Request(
      `https://example.com/api/v1/file/download/?token=${tokenUrl}`,
    );
    const res = await handleDownload(req, env);
    expect(res.status).toBe(404);
  });
});
