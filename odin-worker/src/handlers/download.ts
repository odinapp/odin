import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { extractTokenCode } from '../lib/token';
import { jsonError } from '../lib/response';
import { unwrapEncryptionKey } from '../lib/keywrap';
import { decryptContainerPayload } from '../lib/encrypted_container';

export async function handleDownload(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const rawToken = url.searchParams.get('token') ?? '';
  const token = extractTokenCode(rawToken);
  if (!token) {
    return jsonError(404, 'not found or expired');
  }

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  const object = await env.R2_BUCKET.get(metadata.r2Key);
  if (!object) {
    return jsonError(404, 'not found or expired');
  }

  if (metadata.wrappedEncryptionKey) {
    try {
      const encryptedBytes = new Uint8Array(await object.arrayBuffer());
      const masterKey = await unwrapEncryptionKey(
        metadata.wrappedEncryptionKey,
        env.ENCRYPTION_METADATA_KEY,
      );
      const { payload, manifest } = await decryptContainerPayload(
        encryptedBytes,
        masterKey,
      );
      const manifestName = typeof manifest.name === 'string' && manifest.name.trim().length > 0
        ? manifest.name.trim()
        : metadata.filename;
      const fileName = manifestName.split('/').pop() ?? metadata.filename;
      const isArchive = manifest.zipped === true || metadata.isArchive === true;
      const fileCount =
        typeof manifest.fileCount === 'number' ? manifest.fileCount : metadata.fileCount;
      return new Response(payload, {
        headers: {
          'Content-Type': 'application/octet-stream',
          'Content-Disposition': `attachment; filename="${fileName}"`,
          'Filename': fileName,
          'Content-Length': String(payload.length),
          'X-Odin-Archive': String(isArchive),
          'X-Odin-Encrypted': 'true',
          ...(fileCount ? { 'X-Odin-File-Count': String(fileCount) } : {}),
        },
      });
    } catch {
      return jsonError(500, 'decryption failed');
    }
  }

  return new Response(object.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${metadata.filename}"`,
      'Filename': metadata.filename,
      'Content-Length': String(metadata.size),
      'X-Odin-Archive': String(metadata.isArchive === true),
      'X-Odin-Encrypted': 'false',
      ...(metadata.fileCount ? { 'X-Odin-File-Count': String(metadata.fileCount) } : {}),
    },
  });
}
