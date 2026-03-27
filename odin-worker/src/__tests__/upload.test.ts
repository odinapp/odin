import { describe, it, expect } from 'vitest';
import { env } from 'cloudflare:test';
import { handleUpload } from '../handlers/upload';

function makeUploadRequest(files: { name: string; content: string; fieldName?: string }[]): Request {
  const form = new FormData();
  for (const f of files) {
    form.append(f.fieldName ?? 'file', new File([f.content], f.name));
  }
  form.append('directoryName', 'testdir');
  form.append('totalFileSize', String(files.reduce((s, f) => s + f.content.length, 0)));
  return new Request('https://odin-worker.workers.dev/api/v1/file/upload/', {
    method: 'POST',
    body: form,
  });
}

describe('POST /api/v1/file/upload/', () => {
  it('returns 400 when no file field is present', async () => {
    const form = new FormData();
    form.append('directoryName', 'x');
    const req = new Request('https://example.com/api/v1/file/upload/', { method: 'POST', body: form });
    const res = await handleUpload(req, env);
    expect(res.status).toBe(400);
  });

  it('returns 413 when totalFileSize exceeds 100 MB (checked before reading bytes)', async () => {
    const form = new FormData();
    // Small file but declared size exceeds limit — handler must reject on declared size
    form.append('file', new File(['tiny'], 'tiny.txt'));
    form.append('directoryName', 'x');
    form.append('totalFileSize', String(101 * 1024 * 1024)); // 101 MB declared
    const req = new Request('https://example.com/api/v1/file/upload/', { method: 'POST', body: form });
    const res = await handleUpload(req, env);
    expect(res.status).toBe(413);
  });

  it('returns token and deleteToken on valid single-file upload (file field)', async () => {
    const req = makeUploadRequest([{ name: 'hello.txt', content: 'hello world' }]);
    const res = await handleUpload(req, env);
    expect(res.status).toBe(200);
    const body = await res.json() as { token: string; deleteToken: string };
    expect(body.token).toMatch(/^[A-Za-z0-9]{8}$/);
    expect(body.deleteToken).toMatch(/\/delete\/[A-Za-z0-9]{8}\?secret=[A-Za-z0-9]{16}$/);
  });

  it('accepts the "media" field name (single-file path)', async () => {
    const req = makeUploadRequest([{ name: 'doc.pdf', content: 'pdf-bytes', fieldName: 'media' }]);
    const res = await handleUpload(req, env);
    expect(res.status).toBe(200);
  });

  it('stores file in R2', async () => {
    const req = makeUploadRequest([{ name: 'test.txt', content: 'r2 content' }]);
    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    const r2Object = await env.R2_BUCKET.get(`${body.token}/test.txt`);
    expect(r2Object).not.toBeNull();
  });

  it('stores metadata in KV', async () => {
    const req = makeUploadRequest([{ name: 'meta.txt', content: 'kv test' }]);
    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    const meta = await env.KV_METADATA.get(body.token);
    expect(meta).not.toBeNull();
    const parsed = JSON.parse(meta!);
    expect(parsed.filename).toBe('meta.txt');
    expect(parsed.deleteToken).toHaveLength(16);
  });

  it('zips multiple files and names the upload files.zip', async () => {
    const req = makeUploadRequest([
      { name: 'a.txt', content: 'aaa' },
      { name: 'b.txt', content: 'bbb' },
    ]);
    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    const meta = await env.KV_METADATA.get(body.token);
    expect(JSON.parse(meta!).filename).toBe('files.zip');
  });

  it('succeeds when totalFileSize field is absent', async () => {
    const form = new FormData();
    form.append('file', new File(['hello'], 'x.txt'));
    form.append('directoryName', 'x');
    // no totalFileSize field
    const req = new Request('https://example.com/api/v1/file/upload/', { method: 'POST', body: form });
    const res = await handleUpload(req, env);
    expect(res.status).toBe(200);
  });

  it('stores encrypted manifest preview fields when provided', async () => {
    const form = new FormData();
    form.append('file', new File(['hello'], 'x.odin'));
    form.append('directoryName', 'x');
    form.append('totalFileSize', '5');
    form.append(
      'manifestPreview',
      JSON.stringify({ files: [{ path: 'docs/a.txt', size: 10 }], fileCount: 1, size: 10, zipped: false }),
    );
    form.append('encryptionKey', 'AQIDBAUGBwgJCgsMDQ4PEBESExQVFhcYGRobHB0eHyA');
    form.append('fileCount', '3');
    form.append('originalTotalFileSize', '123');
    form.append('isArchive', 'true');
    const req = new Request('https://example.com/api/v1/file/upload/', { method: 'POST', body: form });

    const res = await handleUpload(req, env);
    const body = await res.json() as { token: string };
    const meta = await env.KV_METADATA.get(body.token);
    const parsed = JSON.parse(meta!);
    expect(parsed.manifestPreview.fileCount).toBe(1);
    expect(parsed.wrappedEncryptionKey).toMatch(/^ODK1\./);
    expect(parsed.encrypted).toBe(true);
    expect(parsed.fileCount).toBe(3);
    expect(parsed.originalTotalFileSize).toBe(123);
    expect(parsed.isArchive).toBe(true);
  });
});
