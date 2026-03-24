import type { Env } from '../types';
import { getMetadata } from '../lib/kv';
import { extractTokenCode } from '../lib/token';
import { jsonError } from '../lib/response';

export async function handleDownload(req: Request, env: Env): Promise<Response> {
  const url = new URL(req.url);
  const rawToken = url.searchParams.get('token') ?? '';
  const token = extractTokenCode(rawToken);

  const metadata = await getMetadata(env.KV_METADATA, token);
  if (!metadata) {
    return jsonError(404, 'not found or expired');
  }

  const object = await env.R2_BUCKET.get(metadata.r2Key);
  if (!object) {
    return jsonError(404, 'not found or expired');
  }

  return new Response(object.body, {
    headers: {
      'Content-Type': 'application/octet-stream',
      'Content-Disposition': `attachment; filename="${metadata.filename}"`,
      'Filename': metadata.filename,
      'Content-Length': String(metadata.size),
    },
  });
}
