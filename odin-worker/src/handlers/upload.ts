import type { Env } from '../types';
import { generateToken, randomString } from '../lib/token';
import { setMetadata, setCleanupEntry } from '../lib/kv';
import { zipFiles } from '../lib/zip';
import { jsonError } from '../lib/response';

const MAX_BYTES = 100 * 1024 * 1024;

export async function handleUpload(req: Request, env: Env): Promise<Response> {
  const contentType = req.headers.get('content-type') ?? '';
  if (!contentType.includes('multipart/form-data')) {
    return jsonError(400, 'no file provided');
  }

  // Reject on Content-Length header before buffering any bytes
  const contentLength = parseInt(req.headers.get('content-length') ?? '0', 10);
  if (!isNaN(contentLength) && contentLength > MAX_BYTES) {
    return jsonError(413, 'file too large');
  }

  let formData: FormData;
  try {
    formData = await req.formData();
  } catch {
    return jsonError(400, 'invalid multipart data');
  }

  // Reject early on declared size before reading any bytes into memory
  const declaredSize = parseInt(formData.get('totalFileSize') as string ?? '0', 10);
  if (!isNaN(declaredSize) && declaredSize > MAX_BYTES) {
    return jsonError(413, 'file too large');
  }

  // Collect files from both 'file' (multi-file path) and 'media' (single-file path)
  const fileEntries: { name: string; data: Uint8Array }[] = [];
  for (const [key, value] of formData.entries()) {
    if ((key === 'file' || key === 'media') && value instanceof File) {
      const buf = await value.arrayBuffer();
      fileEntries.push({ name: value.name, data: new Uint8Array(buf) });
    }
  }

  if (fileEntries.length === 0) {
    return jsonError(400, 'no file provided');
  }

  // Secondary check on actual bytes (guards against mismatched totalFileSize)
  const totalBytes = fileEntries.reduce((sum, f) => sum + f.data.length, 0);
  if (totalBytes > MAX_BYTES) {
    return jsonError(413, 'file too large');
  }

  const finalData = fileEntries.length === 1
    ? fileEntries[0].data
    : zipFiles(fileEntries);
  const finalName = fileEntries.length === 1
    ? fileEntries[0].name
    : 'files.zip';

  let token: string;
  try {
    token = await generateToken(env.KV_METADATA);
  } catch {
    return jsonError(500, 'storage error');
  }

  const r2Key = `${token}/${finalName}`;
  const deleteToken = randomString(16);
  const now = new Date();
  const expiresAt = new Date(now.getTime() + 86400 * 1000);

  try {
    await env.R2_BUCKET.put(r2Key, finalData);
  } catch {
    return jsonError(500, 'storage error');
  }

  try {
    await setMetadata(env.KV_METADATA, token, {
      r2Key,
      filename: finalName,
      size: finalData.length,
      uploadedAt: now.toISOString(),
      expiresAt: expiresAt.toISOString(),
      deleteToken,
    });
    await setCleanupEntry(env.KV_METADATA, token, {
      token,
      r2Key,
      expiresAt: expiresAt.toISOString(),
    });
  } catch {
    return jsonError(500, 'storage error');
  }

  return Response.json({
    token: `${env.PUBLIC_URL}/d/${token}`,
    deleteToken: `${env.PUBLIC_URL}/delete/${token}?secret=${deleteToken}`,
  });
}
