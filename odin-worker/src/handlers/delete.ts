import type { Env } from '../types';
import { getMetadata, deleteMetadata, deleteCleanupEntry } from '../lib/kv';
import { jsonError } from '../lib/response';

export async function handleDelete(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const segments = url.pathname.split('/').filter(Boolean);
  const deleteIndex = segments.indexOf('delete');
  const token = deleteIndex !== -1 ? segments[deleteIndex + 1] ?? '' : '';

  if (!token) {
    return jsonError(404, 'not found');
  }

  const secret = url.searchParams.get('secret') ?? '';

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  if (metadata.deleteToken !== secret) {
    return jsonError(403, 'invalid secret');
  }

  await env.R2_BUCKET.delete(metadata.r2Key);
  await deleteMetadata(env.KV_METADATA, token);
  await deleteCleanupEntry(env.KV_METADATA, token);

  return Response.json({ deleted: true });
}
